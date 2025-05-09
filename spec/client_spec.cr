require "./spec_helper"

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
end
