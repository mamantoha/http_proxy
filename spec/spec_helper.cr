require "spec"
require "../src/http_proxy"

describe HTTP::Proxy do
  it "should have version" do
    (HTTP::Proxy::VERSION).should_not be_nil
  end
end

def with_proxy_server(host = "127.0.0.1", port = 8080, username : String? = nil, password : String? = nil, &)
  wants_close = Channel(Nil).new

  server =
    if username && password
      HTTP::Proxy::Server.new(handlers: [HTTP::Proxy::Server::BasicAuth.new(username, password)])
    else
      HTTP::Proxy::Server.new
    end

  spawn do
    server.bind_tcp(host, port)
    server.listen
  end

  spawn do
    wants_close.receive
    server.close
  end

  Fiber.yield

  yield host, port, username, password, wants_close
end
