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
      @write_timeout : Float64?

      # Creates a new socket factory that tunnels via the given host and port.
      # The following optional arguments are supported:
      #
      # * `:headers` - additional headers, which will be used for tls
      # * `:username` - the user name to use when authenticating to the proxy
      # * `:password` - the password to use when authenticating
      # * `:user_agent` - the User-Agent request header
      def initialize(@host, @port, *,
                     headers : HTTP::Headers? = nil,
                     @username = nil, @password = nil,
                     user_agent = "Crystal, HTTP::Proxy/#{HTTP::Proxy::VERSION}")
        @headers = headers || HTTP::Headers.new
        @headers["User-Agent"] ||= user_agent
      end

      # Returns a new socket connected to the given host and port via the
      # proxy that was requested when the socket factory was instantiated.
      def open(host, port, tls = nil, *, @dns_timeout, @connect_timeout, @read_timeout, @write_timeout) : IO
        socket = TCPSocket.new(@host, @port, @dns_timeout, @connect_timeout)
        socket.read_timeout = @read_timeout if @read_timeout
        socket.write_timeout = @write_timeout if @write_timeout
        socket.sync = false

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
          socket.flush

          resp = HTTP::Client::Response.from_io(socket, ignore_body: true)

          if resp.success?
            {% if !flag?(:without_openssl) %}
              if tls
                socket = OpenSSL::SSL::Socket::Client.new(socket, context: tls, sync_close: true, hostname: host)
              end
            {% end %}
          else
            socket.close

            raise IO::Error.new(resp.inspect)
          end
        end

        socket
      end
    end
  end
end
