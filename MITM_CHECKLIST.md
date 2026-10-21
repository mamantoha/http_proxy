# MITM Production Readiness Checklist

Status key:

- [x] Done
- [ ] Not done
- [~] Partial

## Security

- [ ] Store CA private key outside repository with strict permissions (`600`) and dedicated service account.
- [ ] Add CA key rotation procedure and documented migration plan.
- [ ] Add encrypted CA key / passphrase support.
- [~] Keep sensitive logging disabled by default (`debug: false`), but add redaction for auth/cookies/tokens when debug is enabled.
- [ ] Add host allowlist/denylist policy for MITM interception.

## Certificate Generation

- [x] Dynamic per-host certificate generation is implemented.
- [x] In-process generator is implemented in `src/http/proxy/server/certificate_generator.cr`.
- [x] Certificate cache directory support exists (`certificate_cache_dir`).
- [x] Basic SAN generation exists for DNS/IP hostnames.
- [ ] Serial number strategy should be strengthened (currently timestamp-based).
- [ ] Add cert cache lifecycle controls (TTL/max size/pruning).

## Protocol Behavior

- [x] CONNECT MITM flow for HTTP/1.1 is implemented.
- [x] ALPN is constrained to HTTP/1.1 in server contexts.
- [~] Non-HTTP streams are detected and aborted in MITM path; consider explicit passthrough/tunnel fallback policy.
- [ ] Define and document policy for HTTP/2/HTTP/3 handling in production mode.

## Reliability & Resilience

- [x] Mutex-protected per-host context cache prevents concurrent generation races.
- [ ] Add bounded concurrency / connection limits.
- [ ] Add timeout and retry policy for upstream requests and TLS handshakes.
- [ ] Add graceful shutdown behavior for active MITM sessions under load.
- [ ] Add robust error taxonomy and user-facing failure modes.

## Observability

- [x] Debug output is gated behind `MITMConfig#debug`.
- [ ] Replace ad-hoc debug prints with structured logs for production diagnostics.
- [ ] Add metrics (handshake failures, generation latency, cache hits/misses, upstream status rates).
- [ ] Add health/readiness check endpoint or command.

## Testing

- [ ] Unit tests for certificate generator (key generation, CSR, signing, SAN DNS/IP).
- [ ] Integration tests for browser trust flow (Firefox/Chromium with local CA).
- [ ] Negative tests (invalid CA files, malformed CONNECT targets, broken cert cache files).
- [ ] Load/stress tests for concurrent CONNECT traffic and cert generation.

## Operations

- [~] Runtime sample exists (`samples/server_mitm.cr`) and README usage is documented.
- [ ] Add deployment profile (systemd/service config, restart policy, file permissions).
- [ ] Add operational runbook (bootstrap CA, trust install, rotation, incident recovery).
- [ ] Add secure secret management guidance for CA private key.

## Current Assessment

- Overall maturity: **Advanced MVP / Beta**
- Not yet production-ready due to outstanding hardening, testing depth, and operational controls.
