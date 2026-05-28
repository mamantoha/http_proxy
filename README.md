# HTTP::Proxy

![Crystal CI](https://github.com/mamantoha/http_proxy/workflows/Crystal%20CI/badge.svg)
[![GitHub release](https://img.shields.io/github/release/mamantoha/http_proxy.svg)](https://github.com/mamantoha/http_proxy/releases)
[![License](https://img.shields.io/github/license/mamantoha/http_proxy.svg)](https://github.com/mamantoha/http_proxy/blob/master/LICENSE)

A HTTP Proxy server and client written in Crystal

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  http_proxy:
    github: mamantoha/http_proxy
```

## Usage

### Server

```crystal
require "http_proxy"

host = "127.0.0.1"
port = 8080

server = HTTP::Proxy::Server.new

address = server.bind_tcp(host, port)
puts "Listening on http://#{address}"
server.listen
```

```crystal
require "http_proxy"
require "option_parser"

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

server = HTTP::Proxy::Server.new(handlers: [
  HTTP::LogHandler.new,
]) do |context|
  context.perform
end

address = server.bind_tcp(host, port)
puts "Listening on http://#{address}"
server.listen
```

#### Basic Authentication

```crystal
server = HTTP::Proxy::Server.new(handlers: [
  HTTP::LogHandler.new,
  HTTP::Proxy::Server::BasicAuthHandler.new("user", "passwd"),
]) do |context|
  context.request.headers.add("X-Forwarded-For", "127.0.0.1")
  context.perform
end
```

#### HTTPS MITM (MVP, CONNECT HTTP/1.1 only)

```crystal
server = HTTP::Proxy::Server.new
server.mitm = HTTP::Proxy::Server::MITMConfig.new(
  ca_certificate_path: "./certs/mitm-ca.crt",
  ca_private_key_path: "./certs/mitm-ca.key",
  certificate_cache_dir: "./.mitm-certs",
  debug: false,
)

address = server.bind_tcp("127.0.0.1", 8080)
puts "Listening on http://#{address}"
server.listen
```

Notes:

- This enables HTTPS interception for `CONNECT` requests.
- The certificate authority (CA) used to sign MITM certs must be trusted by clients.
- This MVP is intended for HTTP/1.1 traffic over CONNECT.

Certificate files:

- `mitm-ca.crt` / `mitm-ca.key`: local CA (trust anchor used to sign dynamic leaf certs).
- `./.mitm-certs/*.crt` / `./.mitm-certs/*.key`: generated per-host leaf certificates.

Static mode is still available:

- `mitm.crt` / `mitm.key`: a single leaf certificate and key presented by the proxy.

Firefox setup:

- Import `mitm-ca.crt` in **Authorities** and trust it for websites.
- Do **not** import `mitm.crt` into Authorities.

Server setup:

- Dynamic mode (recommended): pass `mitm-ca.crt` as `ca_certificate_path` and `mitm-ca.key` as `ca_private_key_path`.
- Static mode: pass `mitm.crt` as `certificate_chain_path` and `mitm.key` as `private_key_path`.

Run dynamic MITM sample:

```bash
crystal run samples/server_mitm.cr
```

Useful flags:

- `--ca-cert ./mitm-ca.crt`
- `--ca-key ./mitm-ca.key`
- `--cache-dir ./.mitm-certs`
- `--debug` (enable verbose MITM request/response output)

### Client

#### Make request with proxy

```crystal
require "http_proxy"

proxy_client = HTTP::Proxy::Client.new("127.0.0.1", 8080)

uri = URI.parse("http://httpbingo.org")
client = HTTP::Client.new(uri)
client.proxy = proxy_client
response = client.get("/get")
```

#### Client Authentication

```crystal
uri = URI.parse("https://httpbingo.org")
proxy_client = HTTP::Proxy::Client.new("127.0.0.1", 8080, username: "user", password: "passwd")

response = HTTP::Client.new(uri) do |client|
  client.proxy = proxy_client
  client.get("/get")
end

puts response.status_code
puts response.body
```

## Development

### Proxy server

* [x] Basic HTTP Proxy: GET, POST, PUT, DELETE support
* [x] Basic HTTP Proxy: OPTIONS support
* [x] HTTPS Proxy: CONNECT support
* [x] Make context.request & context.response writable
* [x] Basic Authentication
* [x] MITM HTTPS Proxy (MVP, CONNECT HTTP/1.1)

### Proxy client

* [x] Basic HTTP Proxy: GET, POST, PUT, DELETE support
* [x] Basic HTTP Proxy: OPTIONS support
* [x] HTTPS Proxy: CONNECT support
* [x] Basic Authentication

## Contributing

1. Fork it (<https://github.com/mamantoha/http_proxy/fork>)
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

* [bbtfr](https://github.com/bbtfr) Theo Li - creator, maintainer
* [mamantoha](https://github.com/mamantoha) Anton Maminov - maintainer
