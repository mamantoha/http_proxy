require "../src/http_proxy"
require "kemal"

host = "127.0.0.1"
port = 8080

spawn do
  server = HTTP::Proxy::Server.new(host, port, handlers: [
    HTTP::LogHandler.new,
  ]) do |context|
    context.request.headers.add("X-Forwarded-For", host)
    context.perform
  end
  server.listen
  puts "Listening on http://#{host}:#{port}"
end

Kemal.run
