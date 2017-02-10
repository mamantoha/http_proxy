# proxy

A HTTP Proxy written in Crystal inspired by Ruby's WEBrick::HTTPProxyServer

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  proxy:
    github: bbtfr/proxy.cr
```

## Usage

```crystal
require "http/proxy"

server = HTTP::Proxy.new(8080)

puts "Listening on http://127.0.0.1:8080"
server.listen
```

## Development

* [x] Basic HTTP Proxy: GET, POST, PUT, DELETE support
* [ ] Basic HTTP Proxy: OPTIONS support
* [ ] HTTPS Proxy: CONNECT support
* [ ] MITM HTTPS Proxy

## Contributing

1. Fork it ( https://github.com/bbtfr/proxy/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [bbtfr](https://github.com/bbtfr) Theo Li - creator, maintainer
