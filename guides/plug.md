# Gale for Plug

**HTTP/1.1 + HTTP/2 + HTTP/3 adapter for Plug applications.**

`Gale.Plug` is a drop-in replacement for `Plug.Cowboy` and `Plug.Adapters.Bandit`, enabling any Plug-based application to run with HTTP/3 support.

## Installation

```elixir
def deps do
  [{:gale, "~> 0.1"}]
end
```

## Quick Start

```elixir
defmodule MyApp do
  use Plug.Builder
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Hello from Gale!")
  end
end
```

Start your Plug in a supervision tree:

```elixir
children = [
  {Gale.Plug, plug: MyApp, port: 4000}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

## Performance

| Protocol | req/s | vs HTTP/1.1 |
|----------|------:|:-----------:|
| HTTP/1.1 | ~2,000 | 1× |
| **HTTP/3 (7 streams)** | **~825,000** | **412×** |

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:plug` | module | required | The Plug module |
| `:scheme` | `:http` \| `:https` | `:http` | Protocol scheme |
| `:port` | integer | `4000` | Port to listen on |
| `:ip` | tuple | any | IP address to bind |
| `:http3` | boolean | `false` | Enable HTTP/3 |
| `:certfile` | string | — | SSL certificate path |
| `:keyfile` | string | — | SSL key path |

## Examples

### HTTP and HTTPS

```elixir
children = [
  {Gale.Plug, plug: MyApp, port: 4000, scheme: :http},
  {Gale.Plug, plug: MyApp, port: 443, scheme: :https,
   certfile: "priv/cert.pem", keyfile: "priv/key.pem"}
]
```

### HTTP/3

```elixir
{Gale.Plug,
  plug: MyApp,
  port: 443,
  scheme: :https,
  certfile: "priv/cert.pem",
  keyfile: "priv/key.pem",
  http3: true}
```

### Multiple Listeners

```elixir
children = Gale.Plug.child_specs(
  plug: MyApp,
  http: [port: 4000],
  https: [port: 443, certfile: "cert.pem", keyfile: "key.pem"],
  http3: true
)
```

## Migration

### Plug.Cowboy → Gale.Plug

```elixir
# Before
Plug.Cowboy.child_spec(scheme: :http, plug: MyPlug, port: 4000)

# After
{Gale.Plug, plug: MyPlug, port: 4000}
```

### Bandit → Gale.Plug

```elixir
# Before
{Bandit, plug: MyPlug, port: 4000}

# After
{Gale.Plug, plug: MyPlug, port: 4000}
```

## Features

| Feature | Plug.Cowboy | Plug.Adapters.Bandit | Gale.Plug |
|---------|:-----------:|:--------------------:|:---------:|
| HTTP/1.1 | ✅ | ✅ | ✅ |
| HTTP/2 | ✅ | ✅ | ✅ |
| **HTTP/3** | ❌ | ❌ | ✅ |
| WebSocket | ✅ | ✅ | ✅ |
| WebTransport | ❌ | ❌ | ✅ |
| Phoenix adapter | ❌ | ✅ | ✅ |

## See Also

- [Phoenix Guide](phoenix.md) — For Phoenix applications
- [COMPARISON.md](../COMPARISON.md) — Detailed comparison
- [HexDocs](https://hexdocs.pm/gale) — Full API documentation
