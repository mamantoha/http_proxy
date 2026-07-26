require "./context"

class HTTP::Proxy::Server::Handler
  include HTTP::Handler

  def initialize(@mitm_config_provider : -> HTTP::Proxy::Server::MITMConfig?)
  end

  property next : HTTP::Handler | HTTP::Handler::HandlerProc | HandlerProc?

  def call(context)
    HTTP::Proxy::Server::Context.new(context.request, context.response, @mitm_config_provider.call).perform
  end

  alias HandlerProc = HTTP::Proxy::Server::Context ->
end

require "./handlers/*"
