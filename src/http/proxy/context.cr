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

          buf = Bytes.new(4096)
          while ios = IO.select([upstream, downstream])
            if ios[0] == downstream
              bytesize = downstream.read(buf)
              break if bytesize == 0
              upstream.write(buf[0, bytesize])
            elsif ios[0] == upstream
              bytesize = upstream.read(buf)
              break if bytesize == 0
              downstream.write(buf[0, bytesize])
            end
          end

          upstream.close
          downstream.close
        end
      else
        uri = URI.parse @request.resource
        client = HTTP::Client.new uri
        response = client.exec @request
        @response.headers.merge! response.headers
        @response.status_code = response.status_code
        @response.print response.body
      end
    end
  end
end
