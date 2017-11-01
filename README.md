# HTTP::Proxy::Server

A HTTP Proxy written in Crystal inspired by Ruby's WEBrick::HTTPProxyServer

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  proxy:
    github: mamantoha/http_proxy_server
```

## Usage

```crystal
require "http/proxy/server"

server = HTTP::Proxy::Server.new

puts "Listening on http://#{server.host}:#{server.port}"
server.listen
```

```crystal
require "http/proxy/server"

host = "192.168.0.1"
port = 3128

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
]) do |context|
  context.perform
end

puts "Listening on http://#{server.host}:#{server.port}"
server.listen
```

## Development

* [x] Basic HTTP Proxy: GET, POST, PUT, DELETE support
* [x] Basic HTTP Proxy: OPTIONS support
* [x] HTTPS Proxy: CONNECT support
* [x] Make context.request & context.response writable
* [ ] MITM HTTPS Proxy

## Contributing

1. Fork it ( https://github.com/mamantoha/http_proxy_server/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [bbtfr](https://github.com/bbtfr) Theo Li - creator, maintainer
- [mamantoha](https://github.com/mamantoha) Anton Maminov - maintainer
