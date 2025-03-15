class HTTP::Proxy::Server
  class Context
    # The `HTTP::Request` to process.
    getter request : HTTP::Request

    # The `HTTP::Server::Response` to configure and write to.
    getter response : HTTP::Server::Response

    # :nodoc:
    def initialize(@request : HTTP::Request, @response : HTTP::Server::Response)
    end

    def perform
      case @request.method
      when "OPTIONS"
        @response.headers["Allow"] = "OPTIONS,GET,HEAD,POST,PUT,DELETE,CONNECT"
      when "CONNECT"
        handle_tunneling
      else
        handle_http
      end
    end

    private def handle_tunneling
      host, port = @request.resource.split(":", 2)
      upstream = TCPSocket.new(host, port)

      @response.upgrade do |downstream|
        downstream = downstream.as(TCPSocket)
        downstream.sync = true

        WaitGroup.wait do |wg|
          wg.spawn { transfer(upstream, downstream) }
          wg.spawn { transfer(downstream, upstream) }
        end
      end
    end

    private def transfer(destination, source)
      IO.copy(destination, source)
    rescue ex
      Log.error(exception: ex) { "Unhandled exception on HTTP::Proxy::Server::Context" }
    end

    private def handle_http
      host = @request.hostname || ""
      client = HTTP::Client.new(host)

      @request.headers.delete("Accept-Encoding")

      response = client.exec(@request)

      response.headers.delete("Transfer-Encoding")
      response.headers.delete("Content-Encoding")

      @response.headers.merge!(response.headers)
      @response.status_code = response.status_code
      @response.puts(response.body)
    end
  end
end
