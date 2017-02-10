require "../context"

class HTTP::ProxyHandler
  include HTTP::Handler

  def call(context)
    context = HTTP::Proxy::Context.new(context.request, context.response)
    call_next(context)
    context.perform
  end
end
