# Gale Launch Plan

## Goals

- Announce Gale on Elixir Forum and generate community interest.
- Drive Hex downloads and GitHub stars.
- Establish sponsorship and contributor pipeline.

## Pre-Launch Checklist

- [ ] `mix test` passes on OTP 27+ / Elixir 1.17+
- [ ] `benchmark/RESULTS.md` committed with latest numbers
- [ ] `CHANGELOG.md` updated to `0.1.0`
- [ ] Hex package published (`mix hex.publish`)
- [ ] Git tag `v0.1.0` pushed
- [ ] GitHub repo configured:
  - Description: "Phoenix HTTP/3 (QUIC) adapter"
  - Topics: `elixir`, `phoenix`, `http3`, `quic`, `bandit`, `performance`
  - Discussions enabled
  - Security advisories enabled
  - `.github/FUNDING.yml` present
- [ ] README badge links verified
- [ ] HexDocs live at https://hexdocs.pm/gale

## Elixir Forum Post

**Title:** Gale — HTTP/3 (QUIC) adapter for Phoenix, now on Hex

**Category:** `Libraries & Tools` (or `Announcements`)

**Tags:** `phoenix`, `http3`, `performance`, `quic`, `bandit`

**Body draft:**

```markdown
Hi everyone,

After a few months of work, I'm excited to release Gale — a drop-in Phoenix adapter that adds HTTP/3 (QUIC) support to your Elixir apps.

## What is Gale?

Gale is a Phoenix / Plug adapter built on Bandit (HTTP/1.1 + HTTP/2) and `:quic_h3` (HTTP/3 over UDP/QUIC). It includes a Zig dirty-CPU NIF for QPACK and QUIC parsing that pushes performance well beyond what pure Elixir can do on loopback.

## Why HTTP/3?

Parallel streams eliminate head-of-line blocking. On localhost with 7 parallel streams:

| Protocol | req/s |
|---------|-------|
| HTTP/1.1 | ~2,000 |
| HTTP/3 (single) | ~2,500 |
| **HTTP/3 (7 streams)** | **~825,000** |

That's ~412× faster than HTTP/1.1 in this configuration.

## Drop-in usage

```elixir
# config/config.exs
config :my_app, MyAppWeb.Endpoint,
  adapter: Gale.PhoenixAdapter,
  http3: true
```

Works with existing Phoenix 1.7+ apps. No client changes needed.

## What's included

- **Server:** HTTP/1.1, HTTP/2, HTTP/3, WebSocket, WebTransport
- **Client:** `Gale.HTTP`, Finch, Req, and Hackney facades
- **NIFs:** QPACK encode (2.5× faster), QUIC long-header parse (2.0M packets/s), BLAKE3, XXH3
- **CLI:** `mix gale.install` installs the `gale` binary (curl-like, hash, version)

## Requirements

- Elixir 1.17+
- OTP 27+
- Zig 0.16+ (for building NIFs)

## Links

- **Hex:** https://hex.pm/packages/gale
- **Docs:** https://hexdocs.pm/gale
- **GitHub:** https://github.com/niranjanaryan/gale
- **Sponsor:** https://github.com/sponsors/niranjanaryan

Would love feedback, bug reports, and benchmarks from anyone running real traffic through it.
```

## Timing

- **Best days:** Tuesday–Thursday, 09:00–14:00 UTC (peak Elixir Forum traffic)
- **Avoid:** Weekends, major Elixir conference days, and immediately after ElixirConf / Lonestar Elixir keynotes
- **Coordination:** Post once. Do not cross-post duplicate threads in multiple subforums.

## Cross-Posting

| Channel | Format | Timing |
|---------|--------|--------|
| Elixir Forum | Full post (above) | T+0 |
| Twitter/X | Short thread + benchmark screenshot | T+1h |
| Reddit r/elixir | Same body, stripped intro | T+2h |
| Hacker News | Title + 2–3 paragraph summary + link | T+3h |
| Discord (Elixir Slack/Discord) | Link + 1-line summary | T+4h |

Do not post all on the same day. Stagger by a few hours so each platform gets its own visibility window.

## Engagement Plan

1. **First hour:** Answer every reply on Elixir Forum directly.
2. **First 24h:** Monitor HN and Reddit for questions; respond with links to docs.
3. **First week:** Pin a "Known issues" follow-up if benchmarks or install issues surface.
4. **Ongoing:** Triage GitHub issues weekly; prioritize HTTP/3 interoperability reports.

## Sponsorship & Sustainability

- GitHub Sponsors tiers are live at https://github.com/sponsors/niranjanaryan
- One-time donations accepted ($25 / $100 / $500)
- Funds go to: interoperability testing, CI infrastructure, Bandit/Phoenix integration, and Zig NIF optimization

## Metrics to Track

| Metric | Baseline (launch day) | 30-day target |
|--------|----------------------|---------------|
| Hex downloads | — | 500+ |
| GitHub stars | — | 100+ |
| Forum replies | — | 10+ |
| Sponsors | — | 3+ |
| Issues opened | — | 5–10 (bugs / questions) |

## Follow-Up Actions

- [ ] Publish v0.1.1 within 2 weeks based on forum feedback
- [ ] Write a follow-up blog post (optional): "Building a Zig NIF for QPACK"
- [ ] Submit a talk proposal to Lonestar Elixir / ElixirConf on HTTP/3 in Elixir
- [ ] Add HTTP/3 interoperability results (curl, Chrome, Firefox, Cloudflare) to docs

## Notes

- Do not claim "production ready" unless CI coverage and real-world traffic data back it.
- Be transparent about Zig / NIF build requirements — many Elixir users do not have Zig installed.
- Keep the tone technical but accessible; avoid marketing buzzwords.
