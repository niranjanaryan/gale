# Gale (Phoenix HTTP/3)

Use `adapter: Gale.PhoenixAdapter` instead of `Bandit.PhoenixAdapter`.
Keep Bandit as a dependency. Set `http3: true` (or a keyword list with
`certfile`/`keyfile`) on the endpoint for QUIC. LiveView still uses TCP
websockets. Client: `Gale.get/2` with `protocols: [:http3, :http2, :http1]`.
