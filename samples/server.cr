require "../src/http_proxy"
require "option_parser"

host = "127.0.0.1"
port = 8080
username = "user"
password = "passwd"

OptionParser.parse! do |opts|
  opts.on("-h HOST", "--host HOST", "define host to run server") do |opt|
    host = opt
  end

  opts.on("-p PORT", "--port PORT", "define port to run server") do |opt|
    port = opt.to_i
  end
end

server = HTTP::Proxy::Server.new(host, port, handlers: [
  HTTP::LogHandler.new,
  HTTP::Proxy::Server::BasicAuth.new(username, password),
]) do |context|
  context.request.headers.add("X-Forwarded-For", host)
  context.perform
end

puts "Listening on http://#{host}:#{port}"
server.listen
