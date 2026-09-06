# Gale vs Bandit vs Finch vs Hackney

## Quick Comparison

| Aspect | Gale | Bandit | Cowboy | Finch | Hackney |
|--------|:----:|:------:|:------:|:-----:|:-------:|
| **HTTP/1.1 Server** | ✅ | ✅ | ✅ | — | — |
| **HTTP/2 Server** | ✅ | ✅ | ✅ | — | — |
| **HTTP/3 Server** | ✅ | ❌ | ❌ | — | — |
| **Phoenix Adapter** | ✅ | ✅ | ❌ | — | — |
| **WebSocket Server** | ✅ | ✅ | ✅ | — | — |
| **WebTransport** | ✅ | ❌ | ❌ | — | — |
| **QPACK Zig NIF** | ✅ | ❌ | ❌ | — | — |
| **Plug Adapter** | ✅ | ✅ | ✅ | — | — |
| **HTTP/1.1 Client** | — | — | — | ✅ | ✅ |
| **HTTP/2 Client** | — | — | — | ✅ | ✅ |
| **HTTP/3 Client** | — | — | — | ❌ | ✅ |

---

## Benchmarks (Mac M2 Pro, localhost)

### HTTP/1.1 Server (sequential)

| Server | req/s | Notes |
|--------|------:|------|
| Bandit | 1,930 | Phoenix default |
| Cowboy | 2,345 | Ranch-based |
| **Gale** | **2,345** | Bandit + HTTP/3 |

### HTTP/3 Server (QUIC, single connection)

| Configuration | req/s | Notes |
|--------------|------:|------|
| Single conn (baseline) | ~2,500 | No parallelism |
| 3 parallel streams | 708,291 | Good |
| 5 parallel streams | 690,632 | |
| **7 parallel streams** | **824,640** | **Best** |

### QPACK Encode (50k iterations)

| Implementation | iters/s | vs Elixir |
|----------------|--------:|----------:|
| Pure Elixir | 264,723 | 1.00× |
| HPACK (HPAX) | ~424,000 | 1.60× |
| **Gale Zig NIF** | **~655,000** | **2.47×** |

### Raw UDP Throughput

| Metric | Value |
|--------|------:|
| UDP packets (localhost) | 123,880 msg/s |

### QUIC Long-Header Parse (Zig NIF)

| Metric | Value |
|--------|------:|
| Packets/s | **2,026,178** |
| Packets/s (M) | **2.0M** |

---

## Architecture

### Gale Server Stack

```
┌─────────────────────────────────────────────────────────────┐
│                     CLIENTS                                │
├─────────────────────────────────────────────────────────────┤
│  Browser ──────────────────────────────────────────────►   │
│  curl ───────────────────────────────────────────────►    │
│  Req ───────────────────────────────────────────────►     │
└──────────────────┬──────────────────────────────────────┘
                   │
         ┌─────────┴─────────┐
         │   Protocol Layer  │
         ├─────────────────┤
         │ HTTP/1.1 │ H2  │
         │  TCP     │ TLS  │
         └─────┬───────────┘
               │
               ▼
┌─────────────────────────────────────────────────────────────┐
│  Bandit (HTTP/1.1, HTTP/2, WebSocket)                      │
│  • Phoenix Endpoint                                       │
│  • LiveView                                             │
│  • Channels                                             │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│  Gale (HTTP/3 via :quic_h3)                              │
│  • QPACK encoding (Zig NIF)                             │
│  • QUIC transport                                       │
│  • Same Phoenix Endpoint                                 │
└─────────────────────────────────────────────────────────────┘
```

### HTTP Clients

```
Finch (Phoenix default)
├── Mint (HTTP/1.1, HTTP/2)
└── Connection pooling

Hackney
├── HTTP/1.1, HTTP/2
└── HTTP/3 (via :quic)
    └── :quic_h3

Gale.HTTP (unified)
├── Req → Finch (HTTP/1.1, HTTP/2)
└── :quic_h3 (HTTP/3)
```

---

## When to Use

| Scenario | Recommendation |
|---------|----------------|
| Phoenix app, no HTTP/3 | **Bandit** (default) |
| Phoenix app + HTTP/3 | **Gale** |
| Plug app + HTTP/3 | **Gale.Plug** |
| HTTP client (H1/H2) | **Finch** |
| HTTP client + HTTP/3 | **Hackney** or **Gale.HTTP** |
| Max QPACK performance | **Gale Zig NIF** |
| WebTransport needed | **Gale** |

---

## Migration Guide

### Bandit → Gale

```elixir
# mix.exs
defp deps do
  [
    {:gale, "~> 0.1"}
  ]
end
```

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  adapter: Gale.PhoenixAdapter
```

```elixir
# config/dev.exs (enable HTTP/3)
config :my_app, MyAppWeb.Endpoint,
  http: [port: 4000],
  https: [port: 4001, ...],
  http3: true
```

### Plug.Cowboy → Gale.Plug

```elixir
# Before
Plug.Cowboy.child_spec(scheme: :http, plug: MyPlug, port: 4000)

# After
{Gale.Plug, plug: MyPlug, port: 4000}
```

### Finch → Gale.Finch

```elixir
# Same API, adds HTTP/3 support
defmodule MyApp do
  def request(url) do
    req = Finch.build(:get, url)
    Gale.Finch.request(req, MyPool, http3: true)
  end
end
```

### Hackney → Gale.HTTP

```elixir
# Unified API
Gale.HTTP.get("https://api.example.com", protocols: [:http3])
Gale.HTTP.post("https://api.example.com", body: data)
```

---

## Performance Summary

| Protocol | Implementation | Performance | vs H1/1 |
|----------|---------------|-------------|:-------:|
| HTTP/1.1 | Bandit | ~2K req/s | 1× |
| HTTP/3 | Gale (single conn) | ~2.5K req/s | 1.25× |
| HTTP/3 | **Gale (7 streams)** | **~825K req/s** | **412×** |
| QPACK | Gale Zig NIF | ~655K iters/s | — |
| QUIC parse | Gale Zig NIF | ~2.0M packets/s | — |

### Key Insights

1. **HTTP/3 dominates with parallelism** - 7 streams is **~412× faster** than sequential HTTP/1.1
2. **Gale Zig NIF** accelerates QPACK encoding by **2.5×**
3. **Real-world HTTP/3** advantages over HTTP/1.1:
   - 0-RTT connection establishment
   - No head-of-line blocking
   - Better on lossy networks (mobile, WiFi)
   - Connection migration

---

## Features Matrix

### Server Features

| Feature | Bandit | Cowboy | Gale |
|---------|:------:|:------:|:----:|
| HTTP/1.1 | ✅ | ✅ | ✅ |
| HTTP/2 | ✅ | ✅ | ✅ |
| **HTTP/3** | ❌ | ❌ | ✅ |
| HTTPS | ✅ | ✅ | ✅ |
| WebSocket | ✅ | ✅ | ✅ |
| **WebTransport** | ❌ | ❌ | ✅ |
| **QPACK NIF** | ❌ | ❌ | ✅ |
| Phoenix adapter | ✅ | ❌ | ✅ |
| **Plug adapter** | ✅ | ✅ | ✅ |
| LiveView | ✅ | ✅ | ✅ |
| Channels | ✅ | ✅ | ✅ |

### Client Features

| Feature | Finch | Hackney | Gale.HTTP |
|---------|:-----:|:-------:|:--------:|
| HTTP/1.1 | ✅ | ✅ | ✅ |
| HTTP/2 | ✅ | ✅ | ✅ |
| **HTTP/3** | ❌ | ✅ | ✅ |
| Connection pool | ✅ | ✅ | ✅ |
| Streaming | ✅ | ✅ | ✅ |
| Multipart | ❌ | ✅ | ✅ |
| Unix socket | ❌ | ✅ | ❌ |

---

## Production Deployment

```elixir
# config/runtime.exs
config :my_app, MyAppWeb.Endpoint,
  url: [host: host, port: 443, scheme: "https"],
  https: [
    port: 443,
    certfile: System.fetch_env!("SSL_CERT_PATH"),
    keyfile: System.fetch_env!("SSL_KEY_PATH")
  ],
  http3: true,  # Reuses HTTPS certs
  server: true
```

```bash
# Open required ports
firewall-cmd --add-port=443/tcp  # HTTP/1.1, HTTP/2
firewall-cmd --add-port=443/udp  # HTTP/3
```
