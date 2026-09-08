# Gale Stacks Grant — Submission Checklist

**Portal:** https://portal.stacksendowment.co/apply/cycle-3  
**Deadline:** September 23, 2026  
**Track:** Getting Started Grant  
**Theme:** Distribution & Integrations  

---

## Form Fields

### Project Name
```
Gale — HTTP/3 Transport for Stacks
```

### Track
```
Getting Started Grant
```

### Theme
```
Distribution & Integrations
```

### Problem Statement
```
Stacks ecosystem services — API nodes, block explorers, sBTC relays, wallet backends, and dApp frontends — currently run on HTTP/1.1 or HTTP/2. This creates head-of-line blocking, slow TLS handshakes on mobile, and high cross-region latency. No documented path exists for Stacks Elixir services to adopt HTTP/3. Gale fills this gap as the only drop-in Phoenix/Plug HTTP/3 adapter in Elixir, with Stacks-specific configs and benchmarks.
```

### Solution
```
Gale provides Stacks-optimized HTTP/3 configurations, reproducible benchmarks against real Stacks endpoint patterns, and a drop-in Phoenix/Plug adapter package. Existing services add `adapter: Gale.PhoenixAdapter` and `http3: true` for immediate gains. Gale is unique because it is a production-ready Phoenix adapter with a QPACK NIF and proven performance (~825K req/s on localhost) — not a config snippet or benchmark report.
```

### What You Will Ship
```
Milestone 1 (Week 4): Stacks HTTP/3 configuration guide + benchmarks for Stacks API patterns
Milestone 2 (Week 8): :gale_stacks Hex package + blog post
```

### How This Helps Stacks
```
Makes Stacks API nodes, dApp backends, and sBTC relays faster and more resilient using HTTP/3. Improves mobile wallet performance (sub-100ms response with 0-RTT), reduces cross-region latency, and increases throughput for relay status endpoints (2-3× via parallel streams). Gale is the HTTP/3 execution layer for Stacks services.
```

### Budget
```
$5,000 STX — development (4,000 STX), benchmark infrastructure (500 STX), documentation and content (300 STX), buffer (200 STX)
```

### Team
```
Solo builder with 6+ open-source Elixir projects, including Gale (HTTP/3 Phoenix adapter, ~825K req/s on localhost), Crucible (multi-cloud provisioner), Zeiroh (FLAME overlay), IngotCluster (Iroh+Zenoh), Orian (S3/S5 transfer), and Dusk (Zenoh cluster). All published on Hex.pm with CI and docs.
```

---

## Links

- GitHub: https://github.com/niranjanaryan/gale
- Hex.pm: https://hex.pm/packages/gale
- Benchmarks: https://github.com/niranjanaryan/gale/blob/main/benchmark/RESULTS.md
- Proposal: https://github.com/niranjanaryan/gale/blob/main/STACKS_GRANT.md

---

## Milestones

### Milestone 1
- **Title:** Stacks HTTP/3 Configuration Guide + Benchmarks
- **Amount:** $2,500 STX
- **Duration:** Weeks 1–4
- **Deliverables:**
  - `GALE_STACKS.md` guide for Stacks API nodes and dApps
  - TLS cert automation tips for Let's Encrypt + HTTP/3
  - Reverse-proxy configs (Nginx/Caddy) for gradual HTTP/3 rollout
  - Benchmark `/v2/info`, `/v2/chain_info`, block explorer HTML, and sBTC relay JSON
  - HTTP/3 vs HTTP/2 vs HTTP/1.1 comparison on localhost and simulated cross-region latency
  - Published results with methodology
  - Tests: Gale test suite passes with Stacks-like payload sizes

### Milestone 2 (Final)
- **Title:** Gale Stacks Adapter + Documentation
- **Amount:** $2,500 STX
- **Duration:** Weeks 5–8
- **Deliverables:**
  - `:gale_stacks` Hex package with pre-tuned configs for API nodes, wallet backends, and sBTC relays
  - Integration examples with existing Stacks Elixir libraries
  - Blog post: "Deploying a Stacks API Node with HTTP/3 using Gale"
  - Performance validation confirming benchmarks hold in production-like conditions
  - Final adoption metric: 100+ Hex downloads and 50+ GitHub stars within 30 days of v0.2.0, plus 1+ community-contributed Stacks config within 90 days

---

## Disbursement
```
50% at Milestone 1 (Week 4)
50% at Milestone 2 (Week 8)
```
