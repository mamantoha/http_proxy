require "http"
require "../../ext/http/client"
require "socket"
require "base64"

{% if !flag?(:without_openssl) %}
  require "openssl"
{% end %}

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
      property headers : HTTP::Headers

      getter tls : OpenSSL::SSL::Context::Client?

      @dns_timeout : Float64?
      @connect_timeout : Float64?
      @read_timeout : Float64?

      record Response,
        version : String,
        code : Int32,
        reason : String,
        headers = {} of String => String

      # Creates a new socket factory that tunnels via the given host and port.
      # The following optional arguments are supported:
      #
      # * :headers - additional headers, which will be used for tls connections, which is useful to supply a User-Agent header
      # * :username - the user name to use when authenticating to the proxy
      # * :password - the password to use when authenticating
      def initialize(@host, @port, *, headers : HTTP::Headers? = nil, @username = nil, @password = nil)
        @headers = headers || HTTP::Headers.new
        @headers["User-Agent"] ||= "Crystal, HTTP::Proxy/#{HTTP::Proxy::VERSION}"
      end

      # Returns a new socket connected to the given host and port via the
      # proxy that was requested when the socket factory was instantiated.
      def open(host, port, tls = nil, *, @dns_timeout, @connect_timeout, @read_timeout)
        socket = TCPSocket.new(@host, @port, @dns_timeout, @connect_timeout)
        socket.read_timeout = @read_timeout if @read_timeout
        socket.sync = true

        if tls
          socket << "CONNECT #{host}:#{port} HTTP/1.1\r\n"
          @headers.each do |name, values|
            values.each do |value|
              socket << "#{name}: #{value}\r\n"
            end
          end
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
end
