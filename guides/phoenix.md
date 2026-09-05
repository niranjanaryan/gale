# Gale for Phoenix (QUIC / HTTP/3)

Gale is the Phoenix endpoint adapter that keeps **Bandit** for HTTP/1.1, HTTP/2,
and LiveView websockets, and adds **HTTP/3 over QUIC** on UDP.

## Install

```elixir
# mix.exs
defp deps do
  [
    {:phoenix, "~> 1.8"},
    {:bandit, "~> 1.6"},
    {:gale, path: "../gale"}
  ]
end
```

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  adapter: Gale.PhoenixAdapter,
  url: [host: "example.com"],
  render_errors: [...],
  pubsub_server: MyApp.PubSub,
  live_view: [signing_salt: "..."]
```

Or from the Phoenix app: `mix gale.phoenix`.

## Development

Same as Bandit. HTTP/3 is off unless you generate certs (`mix phx.gen.cert`) and set:

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
  http3: true
```

`http3: true` reuses the HTTPS cert and port for UDP QUIC.

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

Open **TCP 443** (H1/H2) and **UDP 443** (H3). Gale injects

```
alt-svc: h3="host:443"; ma=86400
```

on HTTP responses so browsers switch to QUIC.

## What stays on Bandit

LiveView `/live` websocket, channels, HTTP/2, and the Plug pipeline. HTTP/3
runs the same endpoint Plug (`MyAppWeb.Endpoint`) over QUIC via `quic_h3`.

WebTransport and HTTP/3 websockets are not Phoenix LiveView; LV still needs TCP
WebSocket (or a future WebTransport transport).
