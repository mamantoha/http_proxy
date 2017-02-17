require "./context"

class HTTP::Proxy::Handler
  include HTTP::Handler

  def call(context)
    request = context.request
    response = context.response
    context = HTTP::Proxy::Context.new(request, response)
    call_next(context)
    context.perform
  end
end
