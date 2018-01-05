require "../src/http_proxy"

def with_proxy_server(host = "localhost", port = 8080)
  wants_close = Channel(Nil).new

  server = HTTP::Proxy::Server.new(host, port)

  spawn do
    puts "start proxy server"
    server.listen
  end

  spawn do
    wants_close.receive
    puts "exit proxy server"
    server.close
  end

  Fiber.yield

  yield host, port, wants_close
end

with_proxy_server do |host, port, wants_close|
  puts "start proxy client"

  proxy_client = HTTP::Proxy::Client.new(host, port)

  uri = URI.parse("https://httpbin.org")
  response = HTTP::Client.new(uri) do |client|
    client.set_proxy(proxy_client)
    client.get("/get")
  end

  puts response.status_code
  puts response.body

  puts "exit proxy client"
ensure
  wants_close.send(nil)
end
