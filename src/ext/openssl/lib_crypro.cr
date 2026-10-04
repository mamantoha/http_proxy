require "openssl/lib_crypto"

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
