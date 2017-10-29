require "../http/proxy"

server = HTTP::Proxy.new(8080, handlers: [
  HTTP::LogHandler.new,
]) do |context|
  context.perform

  # context.response.content_type = "text/plain"
  # context.response.clear
  # context.response.puts "Hello world! The time is #{Time.now}"
end

puts "Listening on http://127.0.0.1:8080"
server.listen
