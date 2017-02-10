class HTTP::Proxy < HTTP::Server
  class Context < HTTP::Server::Context

    def perform
      # perform only once
      return if @performed
      @performed = true

      uri = URI.parse @request.resource
      client = HTTP::Client.new uri
      response = client.exec @request
      @response.headers.merge! response.headers
      @response.status_code = response.status_code
      @response.print response.body
    end
  end
end
