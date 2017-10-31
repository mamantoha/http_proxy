require "http/client"
require "http/server"
require "./proxy/handler"
require "./proxy/response"

class HTTP::Proxy < HTTP::Server
  getter :host, :port

  def initialize(@host = "127.0.0.1", @port = 8080)
    handler = HTTP::Proxy.build_middleware
    @processor = RequestProcessor.new(handler)
  end

  def initialize(@host = "127.0.0.1", @port = 8080, &handler : HTTP::Proxy::Handler::Proc)
    handler = HTTP::Proxy.build_middleware(handler)
    @processor = RequestProcessor.new(handler)
  end

  def initialize(@host = "127.0.0.1", @port = 8080, *, handlers : Array(HTTP::Handler), &handler : HTTP::Proxy::Handler::Proc)
    handler = HTTP::Proxy.build_middleware(handlers, handler)
    @processor = RequestProcessor.new(handler)
  end

  def initialize(@host = "127.0.0.1", @port = 8080, *, handlers : Array(HTTP::Handler))
    handler = HTTP::Proxy.build_middleware(handlers)
    @processor = RequestProcessor.new(handler)
  end

  def initialize(@host = "127.0.0.1", @port = 8080, *, handler : HTTP::Handler | HTTP::Proxy::Handler::Proc)
    handler = HTTP::Proxy.build_middleware(handler)
    @processor = RequestProcessor.new(handler)
  end

  def self.build_middleware(handler : HTTP::Proxy::Handler::Proc? = nil)
    proxy_handler = HTTP::Proxy::Handler.new
    proxy_handler.next = handler if handler
    proxy_handler
  end

  def self.build_middleware(handlers, last_handler : HTTP::Proxy::Handler::Proc? = nil)
    proxy_handler = build_middleware(last_handler)
    return proxy_handler if handlers.empty?

    handlers.each_cons(2) do |group|
      group[0].next = group[1]
    end
    handlers.last.next = proxy_handler if proxy_handler

    handlers.first
  end
end
