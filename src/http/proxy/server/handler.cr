require "./context"

class HTTP::Proxy::Server::Handler
  include HTTP::Handler

  property next : HTTP::Handler | HandlerProc | Nil

  def call(context)
    HTTP::Proxy::Server::Context.new(context.request, context.response).perform
  end

  alias HandlerProc = HTTP::Proxy::Server::Context ->
end

require "./handlers/*"
