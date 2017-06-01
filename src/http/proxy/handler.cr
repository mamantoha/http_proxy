require "./context"

class HTTP::Proxy::Handler
  include HTTP::Handler

  property next : Handler | Proc | Nil

  alias Proc = HTTP::Proxy::Context ->

  def call(context)
    request = context.request
    response = context.response
    context = HTTP::Proxy::Context.new(request, response)
    call_next(context)
    context.perform
  end
end
