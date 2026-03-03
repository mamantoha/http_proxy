{% if !flag?(:without_openssl) %}
  require "openssl"
{% end %}

class HTTP::Proxy::Server
  class Context
    # The `HTTP::Request` to process.
    getter request : HTTP::Request

    # The `HTTP::Server::Response` to configure and write to.
    getter response : HTTP::Server::Response

    # :nodoc:
    def initialize(@request : HTTP::Request, @response : HTTP::Server::Response, @mitm : HTTP::Proxy::Server::MITMConfig? = nil)
    end

    def perform
      case @request.method
      when "OPTIONS"
        @response.headers["Allow"] = "OPTIONS,GET,HEAD,POST,PUT,DELETE,CONNECT"
      when "CONNECT"
        {% unless flag?(:without_openssl) %}
          if mitm = @mitm
            handle_tunneling_mitm(mitm)
          else
            handle_tunneling
          end
        {% else %}
          handle_tunneling
        {% end %}
      else
        handle_http
      end
    end

    private def handle_tunneling
      host, port = connect_target
      upstream = TCPSocket.new(host, port)

      @response.upgrade do |downstream|
        downstream = downstream.as(TCPSocket)
        downstream.sync = true

        WaitGroup.wait do |wg|
          wg.spawn { transfer(upstream, downstream) }
          wg.spawn { transfer(downstream, upstream) }
        end
      end
    end

    {% unless flag?(:without_openssl) %}
      private def handle_tunneling_mitm(mitm : HTTP::Proxy::Server::MITMConfig)
        host, port = connect_target

        @response.upgrade do |downstream|
          downstream = downstream.as(TCPSocket)
          downstream.sync = true

          tls_downstream = begin
            OpenSSL::SSL::Socket::Server.new(downstream, context: mitm.server_context_for(host), sync_close: true)
          rescue ex : OpenSSL::SSL::Error
            debug_puts(mitm, "MITM TLS handshake failed for #{host}:#{port} - #{ex.message}")
            next
          end
          tls_downstream.sync = true
          debug_puts(mitm, "MITM TLS established for #{host}:#{port}, ALPN=#{tls_downstream.alpn_protocol || "none"}")

          upstream_tls_context = mitm.upstream_context || OpenSSL::SSL::Context::Client.new

          HTTP::Client.new(host, port, tls: upstream_tls_context) do |upstream_client|
            upstream_client.compress = false
            request_count = 0

            loop do
              request_count += 1
              debug_puts(mitm, "MITM waiting downstream request ##{request_count} for #{host}:#{port}")
              parsed = HTTP::Request.from_io(tls_downstream)

              case parsed
              when Nil
                debug_puts(mitm, "MITM downstream EOF for #{host}:#{port}")
                break
              when HTTP::Status
                debug_puts(mitm, "MITM downstream request parsing failed for #{host}:#{port} (non-HTTP/1.x stream?)")
                break
              when HTTP::Request
                debug_puts(mitm, "MITM request ##{request_count}: #{parsed.method} #{parsed.resource} #{parsed.version} host=#{parsed.headers["Host"]? || "nil"}")

                if parsed.method.in?({"POST", "PUT", "PATCH"})
                  request_body = parsed.body.try(&.gets_to_end) || ""
                  debug_puts(mitm, "MITM request ##{request_count} body bytes=#{request_body.bytesize}")
                  debug_puts(mitm, "MITM request ##{request_count} body BEGIN")
                  debug_puts(mitm, request_body)
                  debug_puts(mitm, "MITM request ##{request_count} body END")

                  content_type = parsed.headers["Content-Type"]?
                  if content_type && content_type.starts_with?("application/x-www-form-urlencoded")
                    begin
                      params = URI::Params.parse(request_body)
                      debug_puts(mitm, "MITM request ##{request_count} form params: #{params}")
                    rescue ex
                      debug_puts(mitm, "MITM request ##{request_count} form params parse failed: #{ex.message}")
                    end
                  end

                  parsed.body = request_body
                end

                parsed.headers.delete("Proxy-Authorization")
                parsed.headers.delete("Proxy-Connection")
                parsed.headers["Accept-Encoding"] = "identity"

                response = upstream_client.exec(parsed)
                debug_puts(mitm, "MITM response ##{request_count}: status=#{response.status_code} keep_alive=#{response.keep_alive?} content_length=#{response.headers["Content-Length"]? || "nil"} transfer_encoding=#{response.headers["Transfer-Encoding"]? || "nil"} content_type=#{response.headers["Content-Type"]? || "nil"}")

                response.consume_body_io
                body_size = response.body.bytesize
                debug_puts(mitm, "MITM response ##{request_count}: buffered body bytes=#{body_size}")
                # debug_puts(mitm, "MITM response ##{request_count} body BEGIN")
                # debug_puts(mitm, response.body)
                # debug_puts(mitm, "MITM response ##{request_count} body END")

                response.headers.delete("Transfer-Encoding")
                response.headers["Content-Length"] = body_size.to_s

                response.to_io(tls_downstream)
                tls_downstream.flush
                debug_puts(mitm, "MITM response ##{request_count} forwarded and flushed")

                keep_alive = parsed.keep_alive? && response.keep_alive?
                debug_puts(mitm, "MITM keep-alive ##{request_count}: request=#{parsed.keep_alive?} response=#{response.keep_alive?} -> #{keep_alive}")
                break unless keep_alive
              end
            end
          end
        end
      rescue ex
        Log.error(exception: ex) { "Unhandled exception on HTTP::Proxy::Server::Context MITM tunnel" }
      end

      private def debug_puts(mitm : HTTP::Proxy::Server::MITMConfig, message : String)
        puts message if mitm.debug
      end
    {% end %}

    private def connect_target : {String, Int32}
      resource = @request.resource
      separator = resource.rindex(':')
      raise IO::Error.new("Invalid CONNECT target: #{resource}") unless separator

      host = resource[0, separator]
      host = host[1..-2] if host.starts_with?('[') && host.ends_with?(']')
      port = resource[(separator + 1)..].to_i
      {host, port}
    rescue ex
      raise IO::Error.new("Invalid CONNECT target: #{resource}", cause: ex)
    end

    private def transfer(destination, source)
      IO.copy(destination, source)
    rescue ex
      Log.error(exception: ex) { "Unhandled exception on HTTP::Proxy::Server::Context" }
    end

    private def handle_http
      host = @request.hostname || ""
      client = HTTP::Client.new(host)

      @request.headers.delete("Accept-Encoding")

      response = client.exec(@request)

      response.headers.delete("Transfer-Encoding")
      response.headers.delete("Content-Encoding")

      @response.headers.merge!(response.headers)
      @response.status_code = response.status_code
      @response.puts(response.body)
    end
  end
end
