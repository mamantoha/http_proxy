require "http/client"
require "http/server"
require "./server/handler"
require "./server/response"

# :nodoc:
class HTTP::Proxy::Server < HTTP::Server
  getter :host, :port

  def initialize(@host = "127.0.0.1", @port = 8080)
    handler = self.class.build_middleware
    @processor = RequestProcessor.new(handler)
  end

  def initialize(@host = "127.0.0.1", @port = 8080, &handler : Handler::Proc)
    handler = self.class.build_middleware(handler)
    @processor = RequestProcessor.new(handler)
  end

  def initialize(@host = "127.0.0.1", @port = 8080, *, handlers : Array(HTTP::Handler), &handler : Handler::Proc)
    handler = self.class.build_middleware(handlers, handler)
    @processor = RequestProcessor.new(handler)
  end

  def initialize(@host = "127.0.0.1", @port = 8080, *, handlers : Array(HTTP::Handler))
    handler = self.class.build_middleware(handlers)
    @processor = RequestProcessor.new(handler)
  end

  def initialize(@host = "127.0.0.1", @port = 8080, *, handler : HTTP::Handler | Handler::Proc)
    handler = self.class.build_middleware(handler)
    @processor = RequestProcessor.new(handler)
  end

  def self.build_middleware(handler : Handler::Proc? = nil)
    proxy_handler = Handler.new
    proxy_handler.next = handler if handler
    proxy_handler
  end

  def self.build_middleware(handlers, last_handler : Handler::Proc? = nil)
    proxy_handler = build_middleware(last_handler)
    return proxy_handler if handlers.empty?

    handlers.each_cons(2) do |group|
      group[0].next = group[1]
    end
    handlers.last.next = proxy_handler if proxy_handler

    handlers.first
  end
end
