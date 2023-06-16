require "../src/http_proxy"
require "option_parser"

host = "127.0.0.1"
port = 8080

if ARGV[0]
  host, port = ARGV[0].split(':')
  port = port.to_i
end

proxy_client = HTTP::Proxy::Client.new(host, port)

puts "Make HTTPs request w/o proxy"
uri = URI.parse("https://httpbingo.org")
client = HTTP::Client.new(uri)
response = client.get("/get")
puts response.status_code
puts response.body

puts "Make HTTPS request with proxy `#{host}:#{port}`"
uri = URI.parse("https://httpbingo.org")
client = HTTP::Client.new(uri)
client.proxy = proxy_client
response = client.get("/get")
puts response.status_code
puts response.body

puts "Make HTTP request with proxy `#{host}:#{port}`"
uri = URI.parse("http://httpbingo.org")
client = HTTP::Client.new(uri)
client.proxy = proxy_client
response = client.get("/get")
puts response.status_code
puts response.body

puts "Make HTTP request with proxy `#{host}:#{port}`"
uri = URI.parse("http://httpbingo.org")
client = HTTP::Client.new(uri)
client.proxy = proxy_client
request = HTTP::Request.new("GET", "/get")
response = client.exec(request)
puts response.status_code
puts response.body
