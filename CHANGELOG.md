# Changelog

## 0.1.0 — 2026-09-06

First public Hex release.

* Phoenix adapter `Gale.PhoenixAdapter`
* HTTP/1.1 + HTTP/2 via Bandit; HTTP/3 via Hex `quic` when `http3: true`
* Zig dirty-CPU NIF: QPACK, HTTP/3 frames, QUIC parse, BLAKE3, XXH3
* Client facades: `Gale.get/2`, Finch, Req, hackney
* `mix gale.phoenix`, `mix bench`, `gale` CLI (`mix gale.install`)
* S3/S5 storage; defers to Orian when the host app has it
