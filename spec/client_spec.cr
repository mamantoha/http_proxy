require "./spec_helper"

class TrackableIO < IO::Memory
  getter? closed_flag = false

  def close
    @closed_flag = true
  end
end

class RecordingProxyClient < HTTP::Proxy::Client
  getter open_calls = 0
  getter opened_ios = [] of TrackableIO

  def initialize(username : String? = nil, password : String? = nil)
    super("127.0.0.1", 8080, username: username, password: password)
  end

  def open(host, port, tls = nil, *, dns_timeout, connect_timeout, read_timeout, write_timeout) : IO
    @open_calls += 1
    io = TrackableIO.new
    @opened_ios << io
    io
  end
end

class HTTP::Client
  def proxy_io_for_spec
    io
  end

  def apply_proxy_authorization_for_spec(request : HTTP::Request)
    apply_proxy_authorization(request)
  end
end

describe HTTP::Proxy::Client do
  describe "#initialize" do
    it "with host and port" do
      client = HTTP::Proxy::Client.new("127.0.0.1", 9090)
      (client.host).should eq("127.0.0.1")
      (client.port).should eq(9090)
      (client.username).should be_nil
      (client.password).should be_nil
    end

    it "with username and password" do
      client = HTTP::Proxy::Client.new("127.0.0.1", 9090, username: "user", password: "password")
      (client.username).should eq("user")
      (client.password).should eq("password")
    end

    describe "HTTP::Client#proxy=" do
      context HTTP::Client do
        it "keeps using proxy after client reconnect" do
          proxy_client = RecordingProxyClient.new
          client = HTTP::Client.new("httpbingo.org")

          client.proxy = proxy_client
          proxy_client.open_calls.should eq(1)

          client.close

          client.proxy_io_for_spec
          proxy_client.open_calls.should eq(2)
        end

        it "clears proxy auth header when proxy is reconfigured without credentials" do
          authenticated_proxy = RecordingProxyClient.new(username: "user", password: "password")
          unauthenticated_proxy = RecordingProxyClient.new
          client = HTTP::Client.new("httpbingo.org")

          client.proxy = authenticated_proxy

          request = HTTP::Request.new("GET", "/")
          client.apply_proxy_authorization_for_spec(request)
          request.headers["Proxy-Authorization"]?.should_not be_nil

          client.proxy = unauthenticated_proxy

          request = HTTP::Request.new("GET", "/")
          client.apply_proxy_authorization_for_spec(request)
          request.headers["Proxy-Authorization"]?.should be_nil
        end

        it "closes previous connection when reconfiguring proxy" do
          first_proxy = RecordingProxyClient.new
          second_proxy = RecordingProxyClient.new
          client = HTTP::Client.new("httpbingo.org")

          client.proxy = first_proxy
          first_proxy.opened_ios.last.closed_flag?.should be_false

          client.proxy = second_proxy

          first_proxy.opened_ios.last.closed_flag?.should be_true
        end

        it "should make HTTP request" do
          with_proxy_server do |host, port, _username, _password, wants_close|
            proxy_client = HTTP::Proxy::Client.new(host, port)

            uri = URI.parse("http://httpbingo.org")
            client = HTTP::Client.new(uri)
            client.proxy = proxy_client
            response = client.get("/get")

            (client.proxy?).should be_true
            (response.status_code).should eq(200)
          ensure
            wants_close.send(nil)
          end
        end

        it "should make HTTPS request", tags: "network" do
          with_proxy_server do |host, port, _username, _password, wants_close|
            proxy_client = HTTP::Proxy::Client.new(host, port)

            uri = URI.parse("https://httpbingo.org")
            client = HTTP::Client.new(uri)
            client.proxy = proxy_client
            response = client.get("/get")

            (client.proxy?).should be_true
            (response.status_code).should eq(200)
          ensure
            wants_close.send(nil)
          end
        end

        it "fails if the proxy server is not reachable" do
          with_proxy_server do |host, _port, _username, _password, wants_close|
            proxy_client = HTTP::Proxy::Client.new(host, 8081)

            uri = URI.parse("http://httpbingo.org")
            client = HTTP::Client.new(uri)

            expect_raises IO::Error, /Failed to open TCP connection to httpbingo.org:80 \(Error connecting to '127.0.0.1:8081':/ do
              client.proxy = proxy_client
            end
          ensure
            wants_close.send(nil)
          end
        end

        context "with authentication" do
          it "should make HTTP request" do
            with_proxy_server(username: "user", password: "passwd") do |host, port, username, password, wants_close|
              proxy_client = HTTP::Proxy::Client.new(host, port, username: username, password: password)

              uri = URI.parse("http://httpbingo.org")
              client = HTTP::Client.new(uri)
              client.proxy = proxy_client
              response = client.get("/get")

              (client.proxy?).should be_true
              (response.status_code).should eq(200)
            ensure
              wants_close.send(nil)
            end
          end

          it "should make HTTPS request", tags: "network" do
            with_proxy_server(username: "user", password: "passwd") do |host, port, username, password, wants_close|
              proxy_client = HTTP::Proxy::Client.new(host, port, username: username, password: password)

              uri = URI.parse("https://httpbingo.org")
              client = HTTP::Client.new(uri)
              client.proxy = proxy_client
              response = client.get("/get")

              (client.proxy?).should be_true
              (response.status_code).should eq(200)
            ensure
              wants_close.send(nil)
            end
          end

          it "should not be success without credentials" do
            with_proxy_server(username: "user", password: "passwd") do |host, port, _username, _password, wants_close|
              proxy_client = HTTP::Proxy::Client.new(host, port, username: "invalid", password: "invalid")

              uri = URI.parse("http://httpbingo.org")
              client = HTTP::Client.new(uri)
              client.proxy = proxy_client
              response = client.get("/invalid")

              (client.proxy?).should be_true
              (response.status_code).should eq(407) # 407 Proxy Authentication Required
            ensure
              wants_close.send(nil)
            end
          end
        end
      end

      context HTTP::Request do
        it "should make HTTP::Request request with proxy" do
          with_proxy_server do |host, port, _username, _password, wants_close|
            proxy_client = HTTP::Proxy::Client.new(host, port)

            uri = URI.parse("http://httpbingo.org")
            client = HTTP::Client.new(uri)
            client.proxy = proxy_client
            request = HTTP::Request.new("GET", "/get")
            response = client.exec(request)

            (client.proxy?).should be_true
            (response.status_code).should eq(200)
          ensure
            wants_close.send(nil)
          end
        end
      end
    end
  end

  {% if !flag?(:without_openssl) %}
    describe "#open" do
      it "closes underlying TCP socket when CONNECT returns non-success status" do
        assert_connect_closes_socket("HTTP/1.1 502 Bad Gateway\r\n\r\n", IO::Error)
      end

      it "closes underlying TCP socket when CONNECT response is invalid" do
        assert_connect_closes_socket("INVALID_HTTP\r\n\r\n", Exception)
      end

      it "closes underlying TCP socket when TLS handshake fails" do
        assert_connect_closes_socket("HTTP/1.1 200 Connection Established\r\n\r\nNOT_TLS\r\n", OpenSSL::SSL::Error)
      end
    end
  {% end %}
end

{% if !flag?(:without_openssl) %}
  private def assert_connect_closes_socket(raw_response : String, expected_error : E.class) forall E
    server = TCPServer.new("127.0.0.1", 0)
    tls_context = OpenSSL::SSL::Context::Client.new
    attempt_done = Channel(Nil).new(1)
    peer_closed = Channel(Bool).new(1)
    server_done = Channel(Nil).new(1)

    spawn do
      if peer = server.accept?
        begin
          while (line = peer.gets) && !line.empty?
          end
          peer << raw_response
          peer.flush
          attempt_done.receive
          peer.read_timeout = 300.milliseconds
          closed = begin
            peer.skip_to_end
            true
          rescue IO::TimeoutError
            false
          rescue IO::Error
            true
          end
          peer_closed.send(closed)
        ensure
          peer.close rescue nil
          server_done.send(nil)
        end
      end
    end

    {% if flag?(:linux) %}
      baseline_fds = Dir.children("/dev/fd").size
    {% end %}

    proxy_client = HTTP::Proxy::Client.new("127.0.0.1", server.local_address.port)

    expect_raises(expected_error) do
      proxy_client.open(
        "example.com",
        443,
        tls: tls_context,
        dns_timeout: 2.seconds,
        connect_timeout: 2.seconds,
        read_timeout: 2.seconds,
        write_timeout: 2.seconds,
      )
    end

    attempt_done.send(nil)
    peer_closed.receive.should be_true
    server_done.receive

    {% if flag?(:linux) %}
      Dir.children("/dev/fd").size.should eq(baseline_fds)
    {% end %}
  ensure
    server.try(&.close)
  end
{% end %}
