require "./context"

class HTTP::Proxy::Handler
  include HTTP::Handler

  def call(context)
    case context.request.method
    when "OPTIONS"
      context.response.headers["Allow"] = "OPTIONS,GET,HEAD,POST,PUT,DELETE,CONNECT"
    else
      context = HTTP::Proxy::Context.new(context.request, context.response)
      call_next(context)
      context.perform
    end
  end
end
