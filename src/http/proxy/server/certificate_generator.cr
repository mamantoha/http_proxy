require "openssl/lib_crypto"
require "socket"

lib LibCrypto
  alias EVP_PKEY = Void*
  alias EVP_PKEY_CTX = Void*
  alias X509_REQ = Void*
  alias ASN1_INTEGER = Void*
  alias ASN1_TIME = Void*

  EVP_PKEY_RSA = 6

  fun evp_pkey_ctx_new_id = EVP_PKEY_CTX_new_id(id : Int32, e : Void*) : EVP_PKEY_CTX
  fun evp_pkey_ctx_free = EVP_PKEY_CTX_free(ctx : EVP_PKEY_CTX)
  fun evp_pkey_keygen_init = EVP_PKEY_keygen_init(ctx : EVP_PKEY_CTX) : Int32
  fun evp_pkey_ctx_ctrl_str = EVP_PKEY_CTX_ctrl_str(ctx : EVP_PKEY_CTX, type : UInt8*, value : UInt8*) : Int32
  fun evp_pkey_keygen = EVP_PKEY_keygen(ctx : EVP_PKEY_CTX, ppkey : EVP_PKEY*) : Int32
  fun evp_pkey_free = EVP_PKEY_free(pkey : EVP_PKEY)

  fun bio_new_file = BIO_new_file(filename : UInt8*, mode : UInt8*) : Bio*
  fun bio_free_all = BIO_free_all(bio : Bio*) : Int32

  fun pem_read_bio_private_key = PEM_read_bio_PrivateKey(bp : Bio*, x : EVP_PKEY*, cb : Void*, u : Void*) : EVP_PKEY
  fun pem_write_bio_private_key = PEM_write_bio_PrivateKey(bp : Bio*, x : EVP_PKEY, enc : Void*, kstr : UInt8*, klen : Int32, cb : Void*, u : Void*) : Int32

  fun pem_read_bio_x509 = PEM_read_bio_X509(bp : Bio*, x : X509*, cb : Void*, u : Void*) : X509
  fun pem_write_bio_x509_req = PEM_write_bio_X509_REQ(bp : Bio*, x : X509_REQ) : Int32
  fun pem_write_bio_x509 = PEM_write_bio_X509(bp : Bio*, x : X509) : Int32

  fun x509_req_new = X509_REQ_new : X509_REQ
  fun x509_req_free = X509_REQ_free(req : X509_REQ)
  fun x509_req_set_version = X509_REQ_set_version(req : X509_REQ, version : Long) : Int32
  fun x509_req_set_subject_name = X509_REQ_set_subject_name(req : X509_REQ, name : X509_NAME) : Int32
  fun x509_req_set_pubkey = X509_REQ_set_pubkey(req : X509_REQ, pkey : EVP_PKEY) : Int32
  fun x509_req_sign = X509_REQ_sign(req : X509_REQ, pkey : EVP_PKEY, md : EVP_MD) : Int32
  fun x509_req_get_subject_name = X509_REQ_get_subject_name(req : X509_REQ) : X509_NAME
  fun x509_req_get_pubkey = X509_REQ_get_pubkey(req : X509_REQ) : EVP_PKEY

  fun x509_set_version = X509_set_version(x : X509, version : Long) : Int32
  fun x509_set_issuer_name = X509_set_issuer_name(x : X509, name : X509_NAME) : Int32
  fun x509_set_pubkey = X509_set_pubkey(x : X509, pkey : EVP_PKEY) : Int32
  fun x509_sign = X509_sign(x : X509, pkey : EVP_PKEY, md : EVP_MD) : Int32
  fun x509_get_serial_number = X509_get_serialNumber(x : X509) : ASN1_INTEGER
  fun x509_getm_not_before = X509_getm_notBefore(x : X509) : ASN1_TIME
  fun x509_getm_not_after = X509_getm_notAfter(x : X509) : ASN1_TIME

  fun asn1_integer_set = ASN1_INTEGER_set(a : ASN1_INTEGER, v : Long) : Int32
  fun x509_gmtime_adj = X509_gmtime_adj(s : ASN1_TIME, adj : Long) : ASN1_TIME
end

class HTTP::Proxy::Server
  class CertificateGenerator
    # Native equivalent of:
    #   openssl genrsa -out <path> <bits>
    def generate_private_key(path : String, bits : Int32 = 2048) : Bool
      ctx = LibCrypto.evp_pkey_ctx_new_id(LibCrypto::EVP_PKEY_RSA, Pointer(Void).null)
      return false if ctx.null?

      pkey = Pointer(LibCrypto::EVP_PKEY).malloc(1, Pointer(Void).null)

      begin
        return false if LibCrypto.evp_pkey_keygen_init(ctx) <= 0
        return false if LibCrypto.evp_pkey_ctx_ctrl_str(ctx, "rsa_keygen_bits".to_unsafe, bits.to_s.to_unsafe) <= 0
        return false if LibCrypto.evp_pkey_keygen(ctx, pkey) <= 0
        return false if pkey.value.null?

        bio = LibCrypto.bio_new_file(path.to_unsafe, "w".to_unsafe)
        return false if bio.null?

        begin
          return false if LibCrypto.pem_write_bio_private_key(bio, pkey.value, Pointer(Void).null, Pointer(UInt8).null, 0, Pointer(Void).null, Pointer(Void).null) != 1
        ensure
          LibCrypto.bio_free_all(bio)
        end

        true
      ensure
        LibCrypto.evp_pkey_free(pkey.value) unless pkey.value.null?
        LibCrypto.evp_pkey_ctx_free(ctx)
      end
    end

    # Native equivalent of the combined CLI flow:
    #   openssl genrsa -out <key_path> 2048
    #   openssl req -new -key <key_path> -out <csr_path> -subj "/CN=<host>"
    #   openssl x509 -req -in <csr_path> -CA <ca_cert_path> -CAkey <ca_key_path> \
    #     -out <cert_path> -days 825 -sha256 -extfile <ext_path>
    def generate(*,
                 host : String,
                 cert_path : String,
                 key_path : String,
                 ca_cert_path : String,
                 ca_key_path : String,
                 serial_path : String) : Bool
      return false unless generate_private_key(key_path)

      host_key = load_private_key(key_path)
      return false if host_key.null?

      ca_cert = load_certificate(ca_cert_path)
      return false if ca_cert.null?

      ca_key = load_private_key(ca_key_path)
      return false if ca_key.null?

      csr = create_csr(host, host_key)
      return false if csr.null?

      cert, serial = sign_csr(host, csr, ca_cert, ca_key)
      return false if cert.null?

      return false unless write_certificate(cert_path, cert)
      File.write(serial_path, serial.to_s)
      true
    ensure
      LibCrypto.x509_req_free(csr) if csr && !csr.null?
      LibCrypto.x509_free(cert) if cert && !cert.null?
      LibCrypto.evp_pkey_free(host_key) if host_key && !host_key.null?
      LibCrypto.x509_free(ca_cert) if ca_cert && !ca_cert.null?
      LibCrypto.evp_pkey_free(ca_key) if ca_key && !ca_key.null?
    end

    # Native equivalent of:
    #   openssl pkey -in <path>
    private def load_private_key(path : String) : LibCrypto::EVP_PKEY
      bio = LibCrypto.bio_new_file(path.to_unsafe, "r".to_unsafe)
      return Pointer(Void).null.as(LibCrypto::EVP_PKEY) if bio.null?

      begin
        key = LibCrypto.pem_read_bio_private_key(bio, Pointer(LibCrypto::EVP_PKEY).null, Pointer(Void).null, Pointer(Void).null)
        key || Pointer(Void).null.as(LibCrypto::EVP_PKEY)
      ensure
        LibCrypto.bio_free_all(bio)
      end
    end

    # Native equivalent of:
    #   openssl x509 -in <path>
    private def load_certificate(path : String) : LibCrypto::X509
      bio = LibCrypto.bio_new_file(path.to_unsafe, "r".to_unsafe)
      return Pointer(Void).null.as(LibCrypto::X509) if bio.null?

      begin
        cert = LibCrypto.pem_read_bio_x509(bio, Pointer(LibCrypto::X509).null, Pointer(Void).null, Pointer(Void).null)
        cert || Pointer(Void).null.as(LibCrypto::X509)
      ensure
        LibCrypto.bio_free_all(bio)
      end
    end

    # Native equivalent of:
    #   openssl req -new -key <host_key> -subj "/CN=<host>"
    private def create_csr(host : String, host_key : LibCrypto::EVP_PKEY) : LibCrypto::X509_REQ
      req = LibCrypto.x509_req_new
      return Pointer(Void).null.as(LibCrypto::X509_REQ) if req.null?

      subject = LibCrypto.x509_name_new
      return Pointer(Void).null.as(LibCrypto::X509_REQ) if subject.null?

      begin
        return Pointer(Void).null.as(LibCrypto::X509_REQ) if LibCrypto.x509_name_add_entry_by_txt(subject, "CN".to_unsafe, LibCrypto::MBSTRING_UTF8, host.to_unsafe, -1, -1, 0).null?
        return Pointer(Void).null.as(LibCrypto::X509_REQ) if LibCrypto.x509_req_set_version(req, 0) != 1
        return Pointer(Void).null.as(LibCrypto::X509_REQ) if LibCrypto.x509_req_set_subject_name(req, subject) != 1
        return Pointer(Void).null.as(LibCrypto::X509_REQ) if LibCrypto.x509_req_set_pubkey(req, host_key) != 1
        return Pointer(Void).null.as(LibCrypto::X509_REQ) if LibCrypto.x509_req_sign(req, host_key, LibCrypto.evp_sha256) <= 0
      ensure
        LibCrypto.x509_name_free(subject)
      end

      req
    end

    # Native equivalent of:
    #   openssl x509 -req -in <csr> -CA <ca_cert> -CAkey <ca_key> \
    #     -days 825 -sha256 -extfile <ext>
    private def sign_csr(host : String, req : LibCrypto::X509_REQ, ca_cert : LibCrypto::X509, ca_key : LibCrypto::EVP_PKEY) : {LibCrypto::X509, Int64}
      cert = LibCrypto.x509_new
      return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if cert.null?

      req_pubkey = LibCrypto.x509_req_get_pubkey(req)
      return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if req_pubkey.null?

      begin
        serial = Time.utc.to_unix

        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if LibCrypto.x509_set_version(cert, 2) != 1
        serial_number = LibCrypto.x509_get_serial_number(cert)
        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if serial_number.null?
        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if LibCrypto.asn1_integer_set(serial_number, serial) != 1

        not_before = LibCrypto.x509_getm_not_before(cert)
        not_after = LibCrypto.x509_getm_not_after(cert)
        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if not_before.null? || not_after.null?
        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if LibCrypto.x509_gmtime_adj(not_before, 0).null?
        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if LibCrypto.x509_gmtime_adj(not_after, 825_i64 * 24 * 60 * 60).null?

        req_subject = LibCrypto.x509_req_get_subject_name(req)
        issuer_subject = LibCrypto.x509_get_subject_name(ca_cert)
        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if req_subject.null? || issuer_subject.null?

        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if LibCrypto.x509_set_subject_name(cert, req_subject) != 1
        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if LibCrypto.x509_set_issuer_name(cert, issuer_subject) != 1
        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if LibCrypto.x509_set_pubkey(cert, req_pubkey) != 1

        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} unless add_extension(cert, "basicConstraints", "critical,CA:FALSE")
        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} unless add_extension(cert, "keyUsage", "critical,digitalSignature,keyEncipherment")
        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} unless add_extension(cert, "extendedKeyUsage", "serverAuth")

        san_value = Socket::IPAddress.valid?(host) ? "IP:#{host}" : "DNS:#{host}"
        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} unless add_extension(cert, "subjectAltName", san_value)

        return {Pointer(Void).null.as(LibCrypto::X509), 0_i64} if LibCrypto.x509_sign(cert, ca_key, LibCrypto.evp_sha256) <= 0

        {cert, serial}
      ensure
        LibCrypto.evp_pkey_free(req_pubkey)
      end
    end

    # Native equivalent of adding extension entries via extfile in `openssl x509 -extfile ...`.
    private def add_extension(cert : LibCrypto::X509, name : String, value : String) : Bool
      nid = LibCrypto.obj_sn2nid(name.to_unsafe)
      nid = LibCrypto.obj_ln2nid(name.to_unsafe) if nid == LibCrypto::NID_undef
      return false if nid == LibCrypto::NID_undef

      ext = LibCrypto.x509v3_ext_nconf_nid(Pointer(Void).null, Pointer(Void).null, nid, value.to_unsafe)
      return false if ext.null?

      begin
        !LibCrypto.x509_add_ext(cert, ext, -1).null?
      ensure
        LibCrypto.x509_extension_free(ext)
      end
    end

    # Native equivalent of:
    #   openssl x509 -out <path>
    private def write_certificate(path : String, cert : LibCrypto::X509) : Bool
      bio = LibCrypto.bio_new_file(path.to_unsafe, "w".to_unsafe)
      return false if bio.null?

      begin
        LibCrypto.pem_write_bio_x509(bio, cert) == 1
      ensure
        LibCrypto.bio_free_all(bio)
      end
    end
  end
end
