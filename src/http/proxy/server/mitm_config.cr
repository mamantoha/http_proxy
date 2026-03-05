require "./certificate_generator"

class HTTP::Proxy::Server
  class MITMConfig
    getter certificate_chain_path : String?
    getter private_key_path : String?
    getter ca_certificate_path : String?
    getter ca_private_key_path : String?
    getter certificate_cache_dir : String
    getter? upstream_insecure : Bool
    getter? debug : Bool

    def initialize(@certificate_chain_path : String, @private_key_path : String, @upstream_insecure : Bool = false, @debug : Bool = false)
      @ca_certificate_path = nil
      @ca_private_key_path = nil
      @certificate_cache_dir = ".mitm-certs"
    end

    def initialize(*, @ca_certificate_path : String, @ca_private_key_path : String,
                   @certificate_cache_dir : String = ".mitm-certs", @upstream_insecure : Bool = false,
                   @debug : Bool = false)
      @certificate_chain_path = nil
      @private_key_path = nil
    end

    {% unless flag?(:without_openssl) %}
      @server_context : OpenSSL::SSL::Context::Server?
      @server_context_by_host = {} of String => OpenSSL::SSL::Context::Server
      @mutex = Mutex.new
      @certificate_generator = CertificateGenerator.new

      def server_context : OpenSSL::SSL::Context::Server
        @server_context ||= begin
          cert_path = @certificate_chain_path
          key_path = @private_key_path
          raise ArgumentError.new("Static MITM mode requires certificate_chain_path and private_key_path") unless cert_path && key_path

          context = OpenSSL::SSL::Context::Server.new
          context.certificate_chain = cert_path
          context.private_key = key_path
          context.alpn_protocol = "http/1.1"
          context
        end
      end

      def server_context_for(host : String) : OpenSSL::SSL::Context::Server
        return server_context unless dynamic_certificates?

        if context = @server_context_by_host[host]?
          return context
        end

        @mutex.synchronize do
          if context = @server_context_by_host[host]?
            return context
          end

          cert_path, key_path = ensure_host_certificate(host)

          context = OpenSSL::SSL::Context::Server.new
          context.certificate_chain = cert_path
          context.private_key = key_path
          context.alpn_protocol = "http/1.1"

          @server_context_by_host[host] = context
          context
        end
      end

      private def dynamic_certificates? : Bool
        !!(@ca_certificate_path && @ca_private_key_path)
      end

      private def ensure_host_certificate(host : String) : {String, String}
        host_key = sanitize_host_for_path(host)
        cert_path = File.join(@certificate_cache_dir, "#{host_key}.crt")
        key_path = File.join(@certificate_cache_dir, "#{host_key}.key")

        return {cert_path, key_path} if File.exists?(cert_path) && File.exists?(key_path)

        Dir.mkdir_p(@certificate_cache_dir)
        create_host_certificate(host, cert_path, key_path, host_key)
        {cert_path, key_path}
      end

      private def sanitize_host_for_path(host : String) : String
        host.gsub(/[^a-zA-Z0-9\.\-]/, "_")
      end

      private def create_host_certificate(host : String, cert_path : String, key_path : String, host_key : String) : Nil
        ca_cert_path = @ca_certificate_path
        ca_key_path = @ca_private_key_path
        raise ArgumentError.new("Dynamic MITM mode requires ca_certificate_path and ca_private_key_path") unless ca_cert_path && ca_key_path

        serial_path = File.join(@certificate_cache_dir, "ca.srl")
        generated = @certificate_generator.generate(
          host: host,
          cert_path: cert_path,
          key_path: key_path,
          ca_cert_path: ca_cert_path,
          ca_key_path: ca_key_path,
          serial_path: serial_path,
        )

        raise IO::Error.new("Certificate generation failed for #{host}") unless generated
      end

      def upstream_context : OpenSSL::SSL::Context::Client?
        return nil unless @upstream_insecure

        context = OpenSSL::SSL::Context::Client.insecure
        context.verify_mode = OpenSSL::SSL::VerifyMode::NONE
        context
      end
    {% end %}
  end
end
