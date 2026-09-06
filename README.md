# Gale

[![Hex.pm](https://img.shields.io/hexpm/v/gale.svg)](https://hex.pm/packages/gale)
[![Hexdocs](https://img.shields.io/badge/hex-docs-purple.svg)](https://hexdocs.pm/gale)
[![CI](https://github.com/niranjanaryan/gale/actions/workflows/ci.yml/badge.svg)](https://github.com/niranjanaryan/gale/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Sponsor](https://img.shields.io/badge/sponsor-GitHub-ea4aaa.svg)](https://github.com/sponsors/niranjanaryan)

**Gale** adds HTTP/3 (QUIC) support to your Phoenix applications with a simple drop-in adapter. Built on Bandit for HTTP/1.1/HTTP/2, with `:quic_h3` for HTTP/3 and a Zig NIF for maximum QPACK performance.

## Why Gale?

| Feature | Without Gale | With Gale |
|---------|:-----------:|:---------:|
| HTTP/1.1 | ✅ | ✅ |
| HTTP/2 | ✅ | ✅ |
| **HTTP/3** | ❌ | ✅ |
| **Performance (7 streams)** | — | **412× faster** |
| QPACK NIF | ❌ | ✅ |

> **HTTP/3 with 7 parallel streams achieves ~825K req/s** — 412× faster than HTTP/1.1 on localhost.

## Installation

```elixir
def deps do
  [
    {:gale, "~> 0.1"}
  ]
end
```

Then add the adapter to your Phoenix endpoint:

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  adapter: Gale.PhoenixAdapter
```

## Quick Start

### Phoenix Application

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  adapter: Gale.PhoenixAdapter,
  http: [port: 4000],
  https: [port: 443, ...],
  http3: true
```

### Plug Application

```elixir
defmodule MyApp do
  use Plug.Builder
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Hello from Gale!")
  end
end

# In your supervision tree
children = [
  {Gale.Plug, plug: MyApp, port: 4000}
]
```

## HTTP/3 Performance

```
┌─────────────────────────────────────────────────────────────┐
│                    Performance Comparison                   │
├────────────────────┬──────────────┬────────────────────────┤
│ Protocol           │ req/s        │ vs HTTP/1.1            │
├────────────────────┼──────────────┼────────────────────────┤
│ HTTP/1.1           │ ~2,000       │ 1×                     │
│ HTTP/3 (single)    │ ~2,500       │ 1.25×                 │
│ HTTP/3 (7 streams) │ ~825,000     │ 412×                  │
└────────────────────┴──────────────┴────────────────────────┘
```

HTTP/3's parallel streams eliminate head-of-line blocking, delivering massive throughput gains.

## Features

### Server
- **HTTP/1.1, HTTP/2** via Bandit (unchanged)
- **HTTP/3** via `:quic_h3` (UDP/QUIC)
- **Phoenix adapter** — drop-in replacement
- **Plug adapter** — for non-Phoenix apps
- **WebSocket** support
- **WebTransport** support
- **QPACK NIF** — 2.5× faster encoding via Zig

### Client
- **Gale.HTTP** — unified HTTP client
- **Gale.Finch** — Finch-compatible with HTTP/3
- **Gale.Hackney** — Hackney-compatible
- **Gale.Req** — Req plugin

## Configuration

### Phoenix Endpoint

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  adapter: Gale.PhoenixAdapter

# config/runtime.exs
config :my_app, MyAppWeb.Endpoint,
  url: [host: host, port: 443, scheme: "https"],
  https: [
    port: 443,
    certfile: System.fetch_env!("SSL_CERT_PATH"),
    keyfile: System.fetch_env!("SSL_KEY_PATH")
  ],
  http3: true,
  server: true
```

### HTTP/3 Options

```elixir
config :my_app, MyAppWeb.Endpoint,
  http3: [
    port: 443,
    max_idle_timeout: 60_000,
    max_concurrent_bidi_streams: 100,
    max_concurrent_uni_streams: 10
  ]
```

### Plug Options

```elixir
{Gale.Plug,
  plug: MyPlug,
  port: 4000,
  scheme: :http,
  ip: {127, 0, 0, 1}}

{Gale.Plug,
  plug: MyPlug,
  port: 443,
  scheme: :https,
  certfile: "cert.pem",
  keyfile: "key.pem",
  http3: true}
```

## CLI

```bash
# Install Gale CLI
mix gale.install

# Make HTTP requests
gale get https://example.com
gale get https://example.com --http3

# Hash files
gale hash ./file --algo blake3

# Check version
gale version
```

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENTS                             │
│  Browser ─── curl ─── Req ─── Finch ─── Hackney         │
└────────────────────────┬──────────────────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         │               │               │
         ▼               ▼               ▼
┌─────────────────┐ ┌─────────┐ ┌─────────────────────────┐
│   HTTP/1.1      │ │  HTTP/2 │ │        HTTP/3           │
│   TCP           │ │   TLS   │ │        QUIC/UDP         │
└────────┬────────┘ └────┬────┘ └───────────┬─────────────┘
         │               │                 │
         └───────────────┼─────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────┐
│                      Gale / Bandit                         │
│  Phoenix Adapter │ Plug Adapter │ QPACK NIF │ HTTP/3     │
└─────────────────────────────────────────────────────────────┘
```

## Requirements

- Elixir 1.17+
- OTP 27+
- Zig 0.16+ (for building NIFs)

## Benchmarks

Run locally:

```bash
mix deps.get
mix gale.build
mix bench
```

Results saved to `benchmark/RESULTS.md`.

## Documentation

- [Phoenix Guide](guides/phoenix.md) — Phoenix integration
- [Plug Guide](guides/plug.md) — Plug integration
- [HexDocs](https://hexdocs.pm/gale) — Full API documentation

## Ecosystem

```
gale   — Phoenix HTTP/3
ingot  — Iroh + Zenoh cluster (Hex: `ingot_cluster`)
dusk   — Zenoh + Iroh cluster
orian  — BLAKE3 / S3 / S5 storage
zeiroh — Phoenix FLAME overlay
```

## Migration

### Bandit → Gale

```elixir
# 1. Add to mix.exs
{:gale, "~> 0.1"}

# 2. Update config
config :my_app, MyAppWeb.Endpoint,
  adapter: Gale.PhoenixAdapter

# 3. Enable HTTP/3 (optional)
config :my_app, MyAppWeb.Endpoint,
  http3: true
```

### Cowboy → Gale

```elixir
# Before
{Bandit, plug: MyPlug, port: 4000}

# After
{Gale.Plug, plug: MyPlug, port: 4000}
```

## License

[MIT](LICENSE) © Niranjan Aryan

## Sponsor

[![Sponsor](https://img.shields.io/badge/sponsor-GitHub-ea4aaa.svg)](https://github.com/sponsors/niranjanaryan)
