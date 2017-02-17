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
        puts "CONNECT: upstream proxy is `#{host}:#{port}'."
        upstream = TCPSocket.new(host, port)
        puts "CONNECT #{host}:#{port} - succeeded"

        @response.reset
        @response.upgrade do |downstream|
          downstream = downstream.as(TCPSocket)
          downstream.sync = true

          begin
            buf = Bytes.new(4096)
            while ios = IO.select([upstream, downstream])
              if ios[0] == downstream
                bytesize = downstream.read(buf)
                puts "CONNECT: #{bytesize} bytes from Downstream"
                upstream.write(buf[0, bytesize])
              elsif ios[0] == upstream
                bytesize = upstream.read(buf)
                break if bytesize == 0
                puts "CONNECT: #{bytesize} bytes from #{host}:#{port}"
                downstream.write(buf[0, bytesize])
              end
            end
          rescue
          end

          upstream.close
          downstream.close
          puts "CONNECT #{host}:#{port} - closed"
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
