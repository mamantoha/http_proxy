require "../src/http_proxy"
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

proxy_client = HTTP::Proxy::Client.new(host, port)

puts "Make HTTP request w/o proxy"
uri = URI.parse("http://httpbin.org")
client = HTTP::Client.new(uri)
response = client.get("/get")
puts response.status_code
puts response.body

puts "Make HTTPS request"
uri = URI.parse("https://httpbin.org")
response = HTTP::Client.new(uri) do |client|
  client.set_proxy(proxy_client)
  client.get("/get")
end
puts response.status_code
puts response.body

puts "Make HTTP request"
uri = URI.parse("http://httpbin.org")
client = HTTP::Client.new(uri)
client.set_proxy(proxy_client)
response = client.get("http://httpbin.org/get")
puts response.status_code
puts response.body
