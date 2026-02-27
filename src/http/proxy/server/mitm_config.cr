class HTTP::Proxy::Server
  class MITMConfig
    getter certificate_chain_path : String
    getter private_key_path : String
    getter upstream_insecure : Bool

    def initialize(@certificate_chain_path : String, @private_key_path : String, @upstream_insecure : Bool = false)
    end

    {% unless flag?(:without_openssl) %}
      @server_context : OpenSSL::SSL::Context::Server?

      def server_context : OpenSSL::SSL::Context::Server
        @server_context ||= begin
          context = OpenSSL::SSL::Context::Server.new
          context.certificate_chain = @certificate_chain_path
          context.private_key = @private_key_path
          context.alpn_protocol = "http/1.1"
          context
        end
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
