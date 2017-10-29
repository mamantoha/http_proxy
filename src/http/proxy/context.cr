class HTTP::Proxy < HTTP::Server
  class Context < HTTP::Server::Context

    def perform
      # perform only once
      return if @performed

      @performed = true

      case @request.method
      when "OPTIONS"
        @response.headers["Allow"] = "OPTIONS,GET,HEAD,POST,PUT,DELETE,CONNECT"
      when "CONNECT"
        host, port = @request.resource.split(":", 2)

        upstream = TCPSocket.new(host, port)

        @response.reset
        @response.upgrade do |downstream|
          downstream = downstream.as(TCPSocket)
          downstream.sync = true

          spawn do
            spawn { IO.copy(upstream, downstream) }
            spawn { IO.copy(downstream, upstream) }
          end
        end
      else
        uri = URI.parse(@request.resource)
        client = HTTP::Client.new(uri)
        response = client.exec(@request)
        @response.headers.merge!(response.headers)
        @response.status_code = response.status_code
        @response.print(response.body)
      end
    end
  end
end
