# Contributing

## Setup

Zig **0.16**, Elixir **1.17+**, OTP **27+**.

```bash
mix deps.get
mix test
mix bench
mix docs
```

## Scope

* Phoenix adapter and HTTP/3 listener
* QPACK/QUIC codec NIF (Zig)
* Client facades over Req/Finch/`quic_h3`
* Benches and docs

LiveView over WebTransport is out of scope until Phoenix has a transport for it.

## Hex

Maintainers: `mix hex.publish` from a clean `main` after `CHANGELOG.md` is
updated. See `PUBLISH.md`.
