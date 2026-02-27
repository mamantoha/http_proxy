require "../src/http_proxy"
require "option_parser"

host = "127.0.0.1"
port = 8080
certificate_chain_path = "./mitm.crt"
private_key_path = "./mitm.key"
upstream_insecure = false

OptionParser.parse do |opts|
  opts.banner = "Usage: crystal run samples/server_mitm.cr -- [arguments]"

  opts.on("-h HOST", "--host HOST", "define host to run server") do |opt|
    host = opt
  end

  opts.on("-p PORT", "--port PORT", "define port to run server") do |opt|
    port = opt.to_i
  end

  opts.on("--cert PATH", "path to MITM certificate chain PEM") do |opt|
    certificate_chain_path = opt
  end

  opts.on("--key PATH", "path to MITM private key PEM") do |opt|
    private_key_path = opt
  end

  opts.on("--upstream-insecure", "disable upstream TLS verification") do
    upstream_insecure = true
  end
end

server = HTTP::Proxy::Server.new(handlers: [
  HTTP::LogHandler.new,
])

server.mitm = HTTP::Proxy::Server::MITMConfig.new(
  certificate_chain_path: certificate_chain_path,
  private_key_path: private_key_path,
  upstream_insecure: upstream_insecure,
)

address = server.bind_tcp(host, port)
puts "Listening on http://#{address}"
puts "MITM mode enabled (CONNECT HTTP/1.1 MVP)"
puts "Certificate: #{certificate_chain_path}"
puts "Private key: #{private_key_path}"
puts "Upstream TLS verification: #{upstream_insecure ? "DISABLED" : "ENABLED"}"
server.listen
