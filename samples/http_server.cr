require "../src/http_proxy"

host = "127.0.0.1"
port = 8080

# Issue
server = HTTP::Proxy::Server.new(host, port)

# Works
# server = HTTP::Proxy::Server.new(host, port, handlers: [
#   HTTP::LogHandler.new,
# ]) do |context|
#   context.request.headers.add("X-Forwarded-For", host)
#   context.perform
# end

puts "Listening on http://#{server.host}:#{server.port}"
server.listen
