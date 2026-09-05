# QUIC / HTTP/3 on the BEAM — what to add next to Elixir

Phoenix and Bandit do **not** speak HTTP/3. Bandit is HTTP/1.1 + HTTP/2 over TCP
(Thousand Island). HTTP/3 needs QUIC over UDP. **Gale** is the Zig-NIF codec
+ `alt-svc` Plug that sits *beside* Bandit, not a replacement.

## Map

| Package | Hex | Role | H3 | How it fits Elixir |
|---|---|---|---|---|
| **Gale** (this) | unpublished | Drop-in Bandit/Phoenix/Finch/Req + H3 | H1/H2 + H3 | `adapter: Gale.PhoenixAdapter`, `{Gale, plug: ...}`, `Gale.get/2` |
| **Bandit** | `bandit` | Phoenix default server | no | Keep for H1/H2 |
| **Cowboy** | `cowboy` | Ranch HTTP server | partial (quicer NIF, not Plug-H3) | `plug_cowboy` still H1/H2 |
| **Mint / Finch / Req** | `mint` `finch` `req` | Clients | no | ALPN `http/1.1` + `h2` only |
| **`quic`** | `quic` 1.8.x | Pure Erlang QUIC + `quic_h3` | yes | Best in-VM transport. Used by hackney, quiver, webtransport, livery |
| **hackney 4.x** | `hackney` | Client | opt-in experimental | `{protocols, [http3, http2, http1]}` |
| **quiver** | `quiver` 0.4 | Elixir client | yes (on `quic`) | Closest Finch-like H3 client |
| **http_fetch** | `http_fetch` | Fetch API | via `quic` | Browser-shaped client |
| **webtransport** | `webtransport` | WT over H2/H3 | yes | Already in phoenix_kit/saas_kit locks |
| **livery** | `livery` | Erlang web framework | H1+H2+H3 | Not Plug/Phoenix |
| **quicer** | git emqx/quic | MsQuic NIF | transport | EMQX MQTT-over-QUIC; Linux/macOS |
| **quichex** | `quichex` 0.3 | quiche Rustler | experimental | Needs Rust; not a Phoenix adapter |
| **requiem** | `requiem` | WebTransport Elixir | experimental | Forked quiche |
| **Caddy / nginx / CF** | proxy | Terminate H3 | yes | **Production Phoenix path** |

## Recommended add-ons (priority)

1. **`quic` + `quic_h3`** — real UDP QUIC/H3 in the VM. Gale can feed QPACK bytes into it later.
2. **`hackney` 4.x or `quiver`** — outbound H3 for Elixir apps (Mint/Req cannot).
3. **Keep Bandit** for inbound H1/H2; advertise H3 with `Gale.Plug.AltSvc` and terminate QUIC at Caddy until a Plug adapter exists.
4. **Do not** wait on Bandit/Mint H3. **Do not** treat quichex/quicer as Phoenix servers.

## Gaps nobody fills yet

- Plug/Phoenix adapter that accepts browser HTTP/3 (UDP listener + TLS-for-QUIC + QPACK + `Plug.Conn`).
- Mint transport for QUIC (would unlock Finch/Req).
- Thousand Island UDP/QUIC acceptor.
