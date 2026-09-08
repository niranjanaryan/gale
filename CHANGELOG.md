# Changelog

## 0.1.1 — 2026-09-08

* Remove `override: true` from hackney dep for Hex compatibility
* Add GitHub Sponsors `.github/FUNDING.yml`
* Add `LAUNCH_PLAN.md` for Elixir Forum launch strategy
* CLI: Burrito single-file binary support via `mix gale.binary`
* CLI: `mix gale.install` prefers Burrito binary, falls back to escript
* Rust benchmark: HTTP/1.1 server + QPACK encode modes

## 0.1.0 — 2026-09-06

First public Hex release.

* Phoenix adapter `Gale.PhoenixAdapter`
* HTTP/1.1 + HTTP/2 via Bandit; HTTP/3 via Hex `quic` when `http3: true`
* Zig dirty-CPU NIF: QPACK, HTTP/3 frames, QUIC parse, BLAKE3, XXH3
* Client facades: `Gale.get/2`, Finch, Req, hackney
* `mix gale.phoenix`, `mix bench`, `gale` CLI (`mix gale.binary` Burrito single file; else escript)
* S3/S5 storage; defers to Orian when the host app has it
