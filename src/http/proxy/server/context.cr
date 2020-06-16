class HTTP::Proxy::Server < HTTP::Server
  class Context < HTTP::Server::Context
    def perform
      return if @performed

      @performed = true

      case @request.method
      when "OPTIONS"
        @response.headers["Allow"] = "OPTIONS,GET,HEAD,POST,PUT,DELETE,CONNECT"
      when "CONNECT"
        host, port = @request.resource.split(":", 2)

        upstream = TCPSocket.new(host, port)

        channel = Channel(Nil).new

        @response.reset
        @response.upgrade do |downstream|
          downstream = downstream.as(TCPSocket)
          downstream.sync = true

          spawn do
            spawn do
              IO.copy(upstream, downstream)
            rescue
              channel.send(nil)
            end

            spawn do
              IO.copy(downstream, upstream)
              channel.send(nil)
            end
          end

          channel.receive
        end
      else
        uri = URI.parse(@request.resource)
        client = HTTP::Client.new(uri)

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
end
