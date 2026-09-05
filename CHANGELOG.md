# Changelog

## Unreleased

* Dirty-CPU Zig NIFs for QPACK/BLAKE3; H3 send_file uses pread; S3/S5 defers to Orian when loaded
* BLAKE3 + XXH3 Zig NIFs; S3 / S5 storage (`Gale.Storage`)

## 0.1.0 — 2026-09-06

First public release.

* Phoenix adapter `Gale.PhoenixAdapter` (drop-in for `Bandit.PhoenixAdapter`)
* HTTP/1.1 + HTTP/2 via Bandit; LiveView websockets unchanged
* HTTP/3 over QUIC via Hex `quic` (`quic_h3`) when `http3: true` and certs are set
* `alt-svc` on H1/H2 so browsers can upgrade
* Zig NIF: QPACK static table, HTTP/3 frames, QUIC varint, long-header parse
* Client facades: `Gale.get/2`, `Gale.Finch`, `Gale.Req`, `Gale.Hackney`
* `mix gale.phoenix` installer
* `mix bench` — QPACK vs Elixir/Rust/HPAX, Bandit vs Cowboy loopback
