# Gale performance

Machine: aarch64-apple-darwin OTP 29
Date: 2026-09-05

## Ecosystem (loaded in this Mix project)

| package | loaded | role |
|---|---|---|
| gale | yes | H3/QPACK Zig NIF + Plug alt-svc (this package) |
| bandit | yes | Phoenix default HTTP/1.1 + HTTP/2 server (no H3) |
| cowboy | yes | Ranch HTTP server; H3 historically via quicer NIF |
| plug | yes | HTTP adapter behaviour (TCP-oriented) |
| mint | yes | Low-level HTTP/1.1 + HTTP/2 client (no H3) |
| finch | yes | Pooled HTTP client on Mint (no H3) |
| req | yes | High-level HTTP client on Finch (no H3) |
| hackney | yes | HTTP/1.1+2+3 client; H3 opt-in via erlang quic |
| quiver | yes | Elixir HTTP client with H3 on erlang quic |
| http_fetch | no | Fetch API; depends on quic |
| quic | yes | Pure Erlang QUIC + quic_h3 (RFC 9000/9114) |
| quic_h3 | yes | HTTP/3 API on :quic |
| webtransport | yes | WebTransport over H2/H3 |
| livery | no | Erlang web framework H1/H2/H3 |
| quicer | no | MsQuic NIF (EMQX) |
| quichex | no | Cloudflare quiche Rustler NIF |
| hpax | yes | HPACK (HTTP/2 headers), not QPACK |
| thousand_island | yes | TCP server under Bandit (no UDP/QUIC) |

## QPACK encode (50000 iters, 7 headers)

| backend | iters/s | vs Elixir |
|---|---:|---:|
| Elixir QPACK | 173661 | 1.00× |
| Gale Zig NIF | 1960093 | 11.29× |
| Rust CLI | 3291405 | 18.95× |
| HPAX (HPACK / HTTP/2) | 579213 | 3.34× |

## QUIC long-header parse (Zig NIF)

2031694 packets/s

## Loopback HTTP/1.1 (Plug `200 ok`, sequential :httpc)

- Bandit: 2000 GETs → **9160 req/s**
- Cowboy: 2000 GETs → **10519 req/s**

## Notes

- Bandit/Cowboy/Mint have no HTTP/3. These numbers are H1 + codec throughput.
- HPAX is HTTP/2 HPACK, included as a header-compression baseline vs QPACK.
- Rust figure is a standalone binary (no NIF call overhead).
- Production H3 for Phoenix: Caddy in front of Bandit; in-VM QUIC via Hex `quic`.
