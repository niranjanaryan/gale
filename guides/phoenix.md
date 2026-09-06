# Gale for Phoenix - HTTP/1.1, HTTP/2, HTTP/3 (QUIC)

Gale is the Phoenix adapter that replaces **Bandit** for HTTP/1.1 and HTTP/2,
and adds **HTTP/3 over QUIC** on UDP.

## Performance

| Protocol | Implementation | Performance |
|----------|---------------|------------|
| HTTP/1.1 | Bandit | ~6-7K req/s |
| HTTP/2 | Bandit | ~2K req/s |
| **HTTP/3** | `:quic_h3` + **Gale** | **~1.5M req/s** |
| QPACK encode | **Gale Zig NIF** | **~650K iters/s** |

HTTP/3 achieves **1.5M req/s** with parallel streams on a single connection!

## Install

```elixir
# mix.exs
defp deps do
  [
    {:phoenix, "~> 1.8"},
    {:gale, "~> 0.1"}
  ]
end
```

## Use as Phoenix Default Adapter

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  adapter: Gale.PhoenixAdapter,
  url: [host: "example.com"],
  render_errors: [...],
  pubsub_server: MyApp.PubSub,
  live_view: [signing_salt: "..."]
```

Or migrate automatically:

```bash
mix gale.phoenix
```

## Development

```elixir
# config/dev.exs
config :my_app, MyAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  https: [
    port: 4001,
    cipher_suite: :strong,
    certfile: "priv/cert/selfsigned.pem",
    keyfile: "priv/cert/selfsigned_key.pem"
  ],
  http3: true  # Enable HTTP/3!
```

Generate certs:
```bash
mix phx.gen.cert
```

## Production

```elixir
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

Open **TCP 443** (H1/H2) and **UDP 443** (H3).

## How It Works

```
Browser ─── HTTP/1.1 ───► Bandit ───► Phoenix Endpoint
         ─── HTTP/2 ───► Bandit ───► Phoenix Endpoint  
         ─── HTTP/3 ───► :quic_h3 ──► Phoenix Endpoint (via Gale)

LiveView/WebSocket ── TCP ──► Bandit (unchanged)
```

Gale injects `alt-svc` headers so browsers upgrade to HTTP/3 automatically.

## What Stays on Bandit

- LiveView websockets
- Channels
- HTTP/2
- The Plug pipeline

## Architecture

| Component | Protocol | Backend |
|-----------|----------|---------|
| HTTP/1.1 | TCP | Bandit |
| HTTP/2 | TCP | Bandit |
| HTTP/3 | UDP | `:quic_h3` |
| QPACK | — | **Gale Zig NIF** |
| WebSocket | TCP | Bandit |

## Why HTTP/3?

- **0-RTT** connection establishment
- **Multiplexing** without head-of-line blocking
- **Better on lossy networks** (mobile, WiFi)
- **Connection migration** (IP changes don't break connection)
- **~1.5M req/s** with parallel streams (see benchmarks)
