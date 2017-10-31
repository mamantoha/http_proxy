require "../http/proxy"
require "option_parser"

host = "127.0.0.1"
port = 8080

OptionParser.parse! do |opts|
  opts.on("-h HOST", "--host HOST", "define host to run server") do |opt|
    host = opt
  end

  opts.on("-p PORT", "--port PORT", "define port to run server") do |opt|
    port = opt.to_i
  end
end

server = HTTP::Proxy.new(host, port, handlers: [
  HTTP::LogHandler.new,
]) do |context|
  context.perform

  # context.response.content_type = "text/plain"
  # context.response.clear
  # context.response.puts "Hello world! The time is #{Time.now}"
end

puts "Listening on http://#{host}:#{port}"
server.listen
