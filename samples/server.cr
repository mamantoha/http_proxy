require "../src/http_proxy"

host = "127.0.0.1"
port = 8080

server = HTTP::Proxy::Server.new(host, port, handlers: [
  HTTP::LogHandler.new,
])

server.bind_tcp(port)

puts "Listening on http://#{server.host}:#{server.port}"
server.listen
