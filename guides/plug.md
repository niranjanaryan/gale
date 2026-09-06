# Using Gale.Plug

`Gale.Plug` provides a drop-in replacement for `Plug.Cowboy` and `Plug.Adapters.Bandit`, enabling any Plug-based application to run on Gale with HTTP/1.1, HTTP/2, and optional HTTP/3 support.

## Quick Start

```elixir
defmodule MyApp do
  use Plug.Builder
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Hello from Gale!")
  end

  get "/json" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, ~s({"message": "Hello!"}))
  end
end
```

## Starting the Server

### Basic Usage

```elixir
# Single server
{:ok, _} = Gale.Plug.start_link(plug: MyApp, port: 4000)
```

### With Supervision Tree

```elixir
children = [
  {Gale.Plug, plug: MyApp, port: 4000}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

### With HTTP and HTTPS

```elixir
children = [
  {Gale.Plug, plug: MyApp, port: 4000, scheme: :http},
  {Gale.Plug, plug: MyApp, port: 4001, scheme: :https,
   certfile: "priv/certs/cert.pem",
   keyfile: "priv/certs/key.pem"}
]

Supervisor.start_link(children, strategy: :one_for_one)
```

## HTTP/3 Support

Enable HTTP/3 with HTTPS:

```elixir
children = [
  {Gale.Plug,
    plug: MyApp,
    scheme: :https,
    port: 443,
    certfile: "priv/certs/cert.pem",
    keyfile: "priv/certs/key.pem",
    http3: true}
]
```

### Using child_specs/1

```elixir
children = Gale.Plug.child_specs(
  plug: MyApp,
  http: [port: 4000],
  https: [port: 443, certfile: "cert.pem", keyfile: "key.pem"],
  http3: true  # Enable HTTP/3 on HTTPS
)
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `:plug` | module | required | The Plug module |
| `:scheme` | `:http` \| `:https` | `:http` | Protocol scheme |
| `:port` | integer | `4000` | Port to listen on |
| `:ip` | tuple | any | IP address to bind |
| `:http3` | boolean \| keyword | `false` | Enable HTTP/3 |
| `:certfile` | string | — | SSL certificate path |
| `:keyfile` | string | — | SSL key path |
| `:thousand_island_options` | keyword | `[]` | Bandit options |
| `:http_options` | keyword | `[]` | HTTP protocol options |
| `:websocket_options` | keyword | `[]` | WebSocket options |

## Phoenix Integration

For Phoenix applications, use `Gale.PhoenixAdapter` instead:

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  adapter: Gale.PhoenixAdapter
```

## WebSocket Support

```elixir
defmodule MySocket do
  @behaviour Plug.Conn.WebSocket

  @impl true
  def init(opts), do: opts

  @impl true
  def websocket_init(opts) do
    {:ok, opts}
  end

  @impl true
  def websocket_handle({:text, msg}, conn) do
    {:reply, {:text, "Echo: #{msg}"}, conn}
  end

  @impl true
  def websocket_terminate(_reason, _conn) do
    :ok
  end
end

# Start with WebSocket
{Gale.Plug, plug: MySocket, port: 4000, websocket_options: [path: "/ws"]}
```

## Migrating from Plug.Cowboy

### Before (Cowboy)

```elixir
# Using Plug.Cowboy
Plug.Cowboy.child_spec(
  scheme: :http,
  plug: MyApp,
  port: 4000
)
```

### After (Gale)

```elixir
# Using Gale.Plug
{Gale.Plug, plug: MyApp, port: 4000}
```

## Migrating from Plug.Adapters.Bandit

### Before (Bandit)

```elixir
# Using Plug.Adapters.Bandit
{Bandit, plug: MyApp, port: 4000}
```

### After (Gale)

```elixir
# Using Gale.Plug
{Gale.Plug, plug: MyApp, port: 4000}
```

## Performance

| Protocol | req/s | Notes |
|----------|------:|-------|
| HTTP/1.1 | ~4,000 | Sequential |
| HTTP/3 (single conn) | ~2,500 | Baseline |
| HTTP/3 (3 streams) | **~820,000** | Parallel |

See [benchmark/RESULTS.md](../benchmark/RESULTS.md) for full benchmarks.

## Comparison with Other Adapters

| Feature | Plug.Cowboy | Plug.Adapters.Bandit | Gale.Plug |
|---------|:-----------:|:--------------------:|:---------:|
| HTTP/1.1 | ✅ | ✅ | ✅ |
| HTTP/2 | ✅ | ✅ | ✅ |
| **HTTP/3** | ❌ | ❌ | ✅ |
| WebSocket | ✅ | ✅ | ✅ |
| **WebTransport** | ❌ | ❌ | ✅ |
| Phoenix adapter | ❌ | ✅ | ✅ |
| **QPACK NIF** | ❌ | ❌ | ✅ |
