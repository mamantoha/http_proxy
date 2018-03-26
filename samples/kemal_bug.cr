require "../src/http_proxy"
require "kemal"

spawn do
  server = HTTP::Proxy::Server.new("127.0.0.1", 8080)

  puts "Listening on http://#{server.host}:#{server.port}"
  server.listen
end

Kemal.run
