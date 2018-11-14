module HTTP
  # :nodoc:
  module Proxy
    # Represents a proxy client with all its attributes.
    # Provides convenient access and modification of them.
    class Client
      getter host : String
      getter port : Int32
      property username : String?
      property password : String?

      getter tls : OpenSSL::SSL::Context::Client?

      record Response,
        version : String,
        code : Int32,
        reason : String,
        headers = {} of String => String

      # Create a new socket factory that tunnels via the given host and  port.
      # The following optional arguments are supported:
      #
      # * :username - the user name to use when authenticating to the proxy
      # * :password - the password to use when authenticating
      def initialize(@host, @port, *, @username = nil, @password = nil)
      end

      # Return a new socket connected to the given host and port via the
      # proxy that was requested when the socket factory was instantiated.
      def open(host, port, tls = nil, connection_options = {} of Symbol => Float64 | Nil)
        dns_timeout = connection_options.fetch(:dns_timeout, nil)
        connect_timeout = connection_options.fetch(:connect_timeout, nil)
        read_timeout = connection_options.fetch(:read_timeout, nil)

        socket = TCPSocket.new(@host, @port, dns_timeout, connect_timeout)
        socket.read_timeout = read_timeout if read_timeout
        socket.sync = true

        if tls
          socket << "CONNECT #{host}:#{port} HTTP/1.0\r\n"
          socket << "Host: #{host}:#{port}\r\n"

          if @username
            credentials = Base64.strict_encode("#{@username}:#{@password}")
            credentials = "#{credentials}\n".gsub(/\s/, "")
            socket << "Proxy-Authorization: Basic #{credentials}\r\n"
          end

          socket << "\r\n"

          resp = parse_response(socket)

          if resp.code == 200
            {% if !flag?(:without_openssl) %}
              if tls
                tls_socket = OpenSSL::SSL::Socket::Client.new(socket, context: tls, sync_close: true, hostname: host)
                socket = tls_socket
              end
            {% end %}

            return socket
          else
            socket.close
            raise IO::Error.new(resp.inspect)
          end
        end

        socket
      end

      private def parse_response(socket) : Response?
        version, code, reason = socket.gets.as(String).chomp.split(/ /, 3)

        headers = {} of String => String

        while (line = socket.gets.as(String)) && (line.chomp != "")
          name, value = line.split(/:/, 2)
          headers[name.strip] = value.strip
        end

        Response.new(version, code.to_i, reason, headers)
      end
    end
  end

  class Client
    def set_proxy(proxy : HTTP::Proxy::Client?)
      return unless proxy

      begin
        @socket = proxy.open(host: @host, port: @port, tls: @tls, connection_options: proxy_connection_options)
      rescue ex : IO::Error
        raise IO::Error.new("Failed to open TCP connection to #{@host}:#{@port} (#{ex.message})")
      end

      if proxy.username
        proxy_basic_auth(proxy.username, proxy.password)
      end

      @socket
    end

    def proxy_connection_options
      opts = {} of Symbol => Float64 | Nil

      opts[:dns_timeout] = @dns_timeout
      opts[:connect_timeout] = @connect_timeout
      opts[:read_timeout] = @read_timeout

      return opts
    end

    private def proxy_basic_auth(username : String?, password : String?)
      header = "Basic #{Base64.strict_encode("#{username}:#{password}")}"
      before_request do |request|
        request.headers["Proxy-Authorization"] = header
      end
    end
  end
end
