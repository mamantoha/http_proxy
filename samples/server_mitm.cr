require "../src/http_proxy"
require "option_parser"

host = "127.0.0.1"
port = 8080
ca_certificate_path = "./mitm-ca.crt"
ca_private_key_path = "./mitm-ca.key"
certificate_cache_dir = "./.mitm-certs"
upstream_insecure = false
debug = false

OptionParser.parse do |opts|
  opts.banner = "Usage: crystal run samples/server_mitm.cr -- [arguments]"

  opts.on("-h HOST", "--host HOST", "define host to run server") do |opt|
    host = opt
  end

  opts.on("-p PORT", "--port PORT", "define port to run server") do |opt|
    port = opt.to_i
  end

  opts.on("--ca-cert PATH", "path to MITM CA certificate PEM (dynamic per-host cert mode)") do |opt|
    ca_certificate_path = opt
  end

  opts.on("--ca-key PATH", "path to MITM CA private key PEM (dynamic per-host cert mode)") do |opt|
    ca_private_key_path = opt
  end

  opts.on("--cache-dir PATH", "directory to store generated host certificates") do |opt|
    certificate_cache_dir = opt
  end

  opts.on("--upstream-insecure", "disable upstream TLS verification") do
    upstream_insecure = true
  end

  opts.on("--debug", "enable verbose MITM request/response debug output") do
    debug = true
  end
end

server = HTTP::Proxy::Server.new(handlers: [
  HTTP::LogHandler.new,
])

server.mitm = HTTP::Proxy::Server::MITMConfig.new(
  ca_certificate_path: ca_certificate_path,
  ca_private_key_path: ca_private_key_path,
  certificate_cache_dir: certificate_cache_dir,
  upstream_insecure: upstream_insecure,
  debug: debug,
)

address = server.bind_tcp(host, port)
puts "Listening on http://#{address}"
puts "MITM mode enabled (CONNECT HTTP/1.1 MVP)"
puts "Certificate mode: dynamic per-host"
puts "CA certificate: #{ca_certificate_path}"
puts "CA private key: #{ca_private_key_path}"
puts "Certificate cache dir: #{certificate_cache_dir}"
puts "Upstream TLS verification: #{upstream_insecure ? "DISABLED" : "ENABLED"}"
puts "MITM debug output: #{debug ? "ENABLED" : "DISABLED"}"
server.listen
