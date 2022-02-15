require "http"

module HTTP
  class Client
    getter proxy : Bool = false

    def set_proxy(proxy : HTTP::Proxy::Client?)
      return unless proxy

      begin
        @io = proxy.open(
          host: @host,
          port: @port,
          tls: @tls,
          dns_timeout: @dns_timeout,
          connect_timeout: @connect_timeout,
          read_timeout: @read_timeout
        )
      rescue ex : IO::Error
        raise IO::Error.new("Failed to open TCP connection to #{@host}:#{@port} (#{ex.message})")
      end

      @proxy = true

      if proxy.username && proxy.password
        proxy_basic_auth(proxy.username, proxy.password)
      end
    end

    # True if requests for this connection will be proxied
    def proxy?
      @proxy
    end

    # Configures this client to perform proxy basic authentication in every
    # request.
    private def proxy_basic_auth(username : String?, password : String?)
      header = "Basic #{Base64.strict_encode("#{username}:#{password}")}"
      before_request do |request|
        request.headers["Proxy-Authorization"] = header
      end
    end
  end
end
