require "http"

module HTTP
  class Client
    getter proxy : HTTP::Proxy::Client? = nil

    @proxy_basic_auth_header : String? = nil

    def proxy=(proxy_client : HTTP::Proxy::Client) : Nil
      close if @io
      @proxy = proxy_client

      begin
        @io = proxy_client.open(
          host: @host,
          port: @port,
          tls: @tls,
          dns_timeout: @dns_timeout,
          connect_timeout: @connect_timeout,
          read_timeout: @read_timeout,
          write_timeout: @write_timeout
        )
      rescue ex : IO::Error
        raise IO::Error.new("Failed to open TCP connection to #{@host}:#{@port} (#{ex.message})")
      end

      if username = proxy_client.username
        if password = proxy_client.password
          @proxy_basic_auth_header = "Basic #{Base64.strict_encode("#{username}:#{password}")}"
        else
          @proxy_basic_auth_header = nil
        end
      else
        @proxy_basic_auth_header = nil
      end
    end

    # True if requests for this connection will be proxied
    def proxy? : Bool
      !!@proxy
    end

    private def apply_proxy_authorization(request : HTTP::Request) : Nil
      if proxy? && (header = @proxy_basic_auth_header)
        request.headers["Proxy-Authorization"] = header
      end
    end

    def_around_exec do |request|
      apply_proxy_authorization(request)
      yield
    end

    # Keep proxy behavior across reconnects by rebuilding @io via proxy as well.
    private def io
      current_io = @io
      return current_io if current_io

      unless @reconnect
        raise "This HTTP::Client cannot be reconnected"
      end

      if proxy = @proxy
        @io = proxy.open(
          host: @host,
          port: @port,
          tls: @tls,
          dns_timeout: @dns_timeout,
          connect_timeout: @connect_timeout,
          read_timeout: @read_timeout,
          write_timeout: @write_timeout
        )
      else
        hostname = @host.starts_with?('[') && @host.ends_with?(']') ? @host[1..-2] : @host
        io = TCPSocket.new(hostname, @port, @dns_timeout, @connect_timeout)
        io.read_timeout = @read_timeout if @read_timeout
        io.write_timeout = @write_timeout if @write_timeout
        io.sync = false

        {% if !flag?(:without_openssl) %}
          if tls = @tls
            tcp_socket = io
            begin
              io = OpenSSL::SSL::Socket::Client.new(tcp_socket, context: tls, sync_close: true, hostname: @host.rchop('.'))
            rescue exc
              # don't leak the TCP socket when the SSL connection failed
              tcp_socket.close
              raise exc
            end
          end
        {% end %}

        @io = io
      end
    end
  end
end
