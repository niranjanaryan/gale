# Gale for Stacks

**HTTP/3 (QUIC) transport for Stacks API nodes, block explorers, wallet backends, and sBTC relays.**

Gale adds HTTP/3 support to your Phoenix/Plug Stacks services. Built on Bandit for HTTP/1.1/HTTP/2, with `:quic_h3` for HTTP/3 and a Zig NIF for maximum QPACK performance.

## Why HTTP/3 for Stacks?

Stacks infrastructure runs on HTTP/1.1/HTTP/2. HTTP/3 eliminates head-of-line blocking, reduces connection setup latency, and improves mobile performance — critical for wallet backends and cross-region API access.

| Protocol | req/s | vs HTTP/1.1 |
|---------|-------|-------------|
| HTTP/1.1 | ~2,000 | 1× |
| HTTP/2 | ~2,500 | 1.25× |
| **HTTP/3 (7 streams)** | **~825,000** | **412×** |

## Installation

```elixir
# mix.exs
def deps do
  [
    {:gale, "~> 0.1"},
    {:gale_stacks, "~> 0.1", optional: true}
  ]
end
```

## Quick Start

### Stacks API Node

```elixir
# config/config.exs
config :stacks_node, StacksNodeWeb.Endpoint,
  adapter: Gale.PhoenixAdapter,
  http: [port: 4000],
  https: [
    port: 443,
    certfile: System.fetch_env!("SSL_CERT_PATH"),
    keyfile: System.fetch_env!("SSL_KEY_PATH")
  ],
  http3: true
```

### sBTC Relay

```elixir
# config/config.exs
config :sbtc_relay, SbtcRelayWeb.Endpoint,
  adapter: Gale.PhoenixAdapter,
  http3: [
    port: 443,
    max_concurrent_bidi_streams: 200,
    max_idle_timeout: 120_000
  ]
```

### Wallet Backend

```elixir
# config/config.exs
config :wallet_backend, WalletBackendWeb.Endpoint,
  adapter: Gale.PhoenixAdapter,
  http3: [
    port: 443,
    max_concurrent_bidi_streams: 100,
    max_idle_timeout: 60_000
  ]
```

## Configuration

### HTTP/3 Options

```elixir
config :stacks_node, StacksNodeWeb.Endpoint,
  http3: [
    port: 443,
    max_idle_timeout: 60_000,
    max_concurrent_bidi_streams: 100,
    max_concurrent_uni_streams: 10
  ]
```

### Using Gale.Stacks Presets

```elixir
# config/config.exs
config :stacks_node, StacksNodeWeb.Endpoint,
  adapter: Gale.PhoenixAdapter,
  http3: Gale.Stacks.api_node_config()
```

Available presets:
- `Gale.Stacks.api_node_config/0` — high-concurrency API node
- `Gale.Stacks.wallet_backend_config/0` — low-latency wallet backend
- `Gale.Stacks.sbtc_relay_config/0` — sBTC relay HTTP client/server

## Client Usage

```elixir
# sBTC relay status
Gale.Req.get!("https://relay.stacks.co/status", http3: true)

# Stacks API node
Gale.HTTP.get!("https://api.stacks.co/v2/info", http3: true)
```

## Benchmarks

Run Stacks-specific benchmarks:

```bash
mix deps.get
mix gale.build
mix bench.stacks
```

Results are saved to `benchmark/STACKS_BENCHMARKS.md`.

## Performance

Gale achieves ~825K req/s on HTTP/3 with 7 parallel streams on localhost — 412× faster than HTTP/1.1.

The Zig QPACK NIF provides 2.5× faster encoding than pure Elixir, reducing header compression overhead for Stacks API responses.

## TLS / Reverse Proxy

For production, use Let's Encrypt + Caddy/Nginx:

```bash
# Caddy
caddy reverse-proxy --from https://stacks-node.example.com --to http://localhost:4000

# Nginx
location / {
  proxy_pass http://localhost:4000;
  proxy_set_header Host $host;
  # HTTP/3 via quic module
}
```

## Requirements

- Elixir 1.17+
- OTP 27+
- Zig 0.16+ (for building NIFs)

## Architecture

```
Browser ─── HTTP/1.1 ───► Bandit ───► Phoenix Endpoint
          ─── HTTP/2 ────► Bandit ───► Phoenix Endpoint
          ─── HTTP/3 ────► QUIC ──────► Phoenix Endpoint

Stacks API nodes, block explorers, wallet backends, sBTC relays
all benefit from HTTP/3's parallel streams and reduced latency.
```

## Migration from Bandit/Cowboy

```elixir
# Before
config :stacks_node, StacksNodeWeb.Endpoint,
  adapter: Bandit.PhoenixAdapter

# After
config :stacks_node, StacksNodeWeb.Endpoint,
  adapter: Gale.PhoenixAdapter,
  http3: true
```

## See Also

- [Gale README](../README.md) — Full documentation
- [GALE_STACKS.md](GALE_STACKS.md) — Stacks-specific deployment guide
- [benchmark/STACKS_BENCHMARKS.md](../benchmark/STACKS_BENCHMARKS.md) — Performance results
- [HexDocs](https://hexdocs.pm/gale) — API documentation
