# Gale for Phoenix

**HTTP/1.1 + HTTP/2 + HTTP/3 (QUIC) adapter for Phoenix applications.**

Gale replaces Bandit for HTTP/1.1 and HTTP/2, and adds HTTP/3 over QUIC on UDP.

## Installation

```elixir
# mix.exs
def deps do
  [{:gale, "~> 0.1"}]
end
```

## Quick Start

### 1. Configure Phoenix Endpoint

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  adapter: Gale.PhoenixAdapter
```

Or use the generator:

```bash
mix gale.phoenix
```

### 2. Enable HTTP/3 (optional)

```elixir
# config/dev.exs or config/runtime.exs
config :my_app, MyAppWeb.Endpoint,
  https: [port: 443, certfile: "...", keyfile: "..."],
  http3: true
```

### 3. Open Firewall

```bash
# TCP for HTTP/1.1, HTTP/2
firewall-cmd --add-port=443/tcp

# UDP for HTTP/3
firewall-cmd --add-port=443/udp
```

## Performance

| Protocol | req/s | vs HTTP/1.1 |
|----------|------:|:-----------:|
| HTTP/1.1 | ~2,000 | 1× |
| HTTP/2 | ~2,500 | 1.25× |
| **HTTP/3 (7 streams)** | **~825,000** | **412×** |

## Configuration

### Development

```elixir
# config/dev.exs
config :my_app, MyAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  https: [port: 4001, certfile: "...", keyfile: "..."],
  http3: true
```

Generate self-signed certs:
```bash
mix phx.gen.cert
```

### Production

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

## How It Works

```
Browser ─── HTTP/1.1 ───► Bandit ───► Phoenix Endpoint
         ─── HTTP/2 ────► Bandit ───► Phoenix Endpoint
         ─── HTTP/3 ────► QUIC ──────► Phoenix Endpoint

LiveView/WebSocket ─── TCP ──► Bandit (unchanged)
```

Gale sends `alt-svc: h3="host:443"` headers so browsers upgrade to HTTP/3.

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

## Troubleshooting

### Browser doesn't upgrade to HTTP/3

1. Check **UDP 443** is open
2. Verify valid SSL certificates
3. Check `alt-svc` header in responses
4. Ensure `:quic_h3` started successfully

## See Also

- [Plug Guide](plug.md) — For non-Phoenix Plug applications
- [COMPARISON.md](../COMPARISON.md) — Detailed Gale vs Bandit comparison
- [benchmark/RESULTS.md](../benchmark/RESULTS.md) — Performance benchmarks
