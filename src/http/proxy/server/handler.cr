require "./context"

class HTTP::Proxy::Server::Handler
  include HTTP::Handler

  property next : Handler | Proc | Nil

  alias Proc = Context ->

  def call(context)
    request = context.request
    response = context.response
    context = Context.new(request, response)
    call_next(context)
    context.perform
  end
end
