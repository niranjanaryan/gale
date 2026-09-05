# Gale

[![Hex.pm](https://img.shields.io/hexpm/v/gale.svg)](https://hex.pm/packages/gale)
[![Hexdocs](https://img.shields.io/badge/hex-docs-purple.svg)](https://hexdocs.pm/gale)
[![CI](https://github.com/niranjanaryan/gale/actions/workflows/ci.yml/badge.svg)](https://github.com/niranjanaryan/gale/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub-ea4aaa.svg)](https://github.com/sponsors/niranjanaryan)

Phoenix adapter for **HTTP/1.1 + HTTP/2 + HTTP/3 (QUIC)**.

LiveView and websockets stay on [Bandit](https://github.com/mtrudel/bandit) (TCP).
HTTP/3 is UDP QUIC via Hex [`quic`](https://hex.pm/packages/quic). A Zig NIF
handles QPACK and HTTP/3 frames.

## Install

```elixir
def deps do
  [{:gale, "~> 0.1"}]
end
```

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  adapter: Gale.PhoenixAdapter
```

From an existing Phoenix app: `mix gale.phoenix`.

Production HTTP/3 (`config/runtime.exs`):

```elixir
config :my_app, MyAppWeb.Endpoint,
  https: [port: 443, certfile: cert, keyfile: key],
  http3: true
```

Open **TCP 443** and **UDP 443**. Gale sends `alt-svc: h3="host:443"` on HTTP
responses so browsers can upgrade.

Full guide: [guides/phoenix.md](guides/phoenix.md).

Storage (BLAKE3 CIDs, S3 / S5): `Gale.Storage.put(body)`. See [HASH.md](HASH.md).

## Client

```elixir
Gale.get("https://example.com")
Gale.get(url, protocols: [:http3, :http2, :http1])
{Gale.Finch, name: MyFinch}
```

## Develop

Requires **Zig 0.16**, Elixir 1.17+, OTP 27+.

```bash
mix deps.get
mix test
mix bench
mix docs
```

## Hex & GitHub

Canonical repo: [github.com/niranjanaryan/gale](https://github.com/niranjanaryan/gale).
Publish steps: [PUBLISH.md](PUBLISH.md). Funding: [FUNDING.md](FUNDING.md).

## License

[MIT](LICENSE) © Niranjan Aryan
