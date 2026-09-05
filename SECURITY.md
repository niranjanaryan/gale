# Security

Report vulnerabilities privately: GitHub Security Advisories on
[niranjanaryan/gale](https://github.com/niranjanaryan/gale), or via
[GitHub Sponsors](https://github.com/sponsors/niranjanaryan).

Do not file public issues for TLS, cert handling, or QUIC parsing bugs.

The Zig NIF is a codec (QPACK/frames). The QUIC handshake and TLS are
Hex `quic` (erlang_quic). Treat both as in-scope.
