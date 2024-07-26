require "http"

module HTTP
  class Client
    getter proxy : HTTP::Proxy::Client? = nil

    def proxy=(proxy_client : HTTP::Proxy::Client) : Nil
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

      if proxy_client.username && proxy_client.password
        proxy_basic_auth(proxy_client.username, proxy_client.password)
      end
    end

    # True if requests for this connection will be proxied
    def proxy? : Bool
      !!@proxy
    end

    # Configures this client to perform proxy basic authentication in every
    # request.
    private def proxy_basic_auth(username : String?, password : String?) : Nil
      header = "Basic #{Base64.strict_encode("#{username}:#{password}")}"
      before_request do |request|
        request.headers["Proxy-Authorization"] = header
      end
    end
  end
end
