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
Stacks ecosystem services — API nodes, block explorers, sBTC relays, wallet backends, and dApp frontends — currently run on HTTP/1.1 or HTTP/2. This creates head-of-line blocking, slow TLS handshakes on mobile, and high cross-region latency. No documented path exists for Stacks Elixir services to adopt HTTP/3.
```

### Solution
```
Gale provides Stacks-optimized HTTP/3 configurations, reproducible benchmarks against real Stacks endpoint patterns, and a drop-in Phoenix/Plug adapter package. Existing services add `adapter: Gale.PhoenixAdapter` and `http3: true` for immediate gains.
```

### What You Will Ship
```
Milestone 1 (Week 3): Stacks HTTP/3 configuration guide with production-ready TLS, port, and reverse-proxy configs
Milestone 2 (Week 6): Reproducible benchmarks for /v2/info, /v2/chain_info, block explorer HTML, and sBTC relay JSON
Milestone 3 (Week 8): :gale_stacks Hex package with pre-tuned configs for API nodes, wallet backends, and sBTC relays
```

### How This Helps Stacks
```
Makes Stacks API nodes, dApp backends, and sBTC relays faster and more resilient using HTTP/3. Improves mobile wallet performance, reduces cross-region latency, and increases throughput for relay status endpoints.
```

### Budget
```
$5,000 STX — development (4,000 STX), benchmark infrastructure (500 STX), documentation and content (300 STX), buffer (200 STX)
```

### Team
```
Solo builder with 6+ open-source Elixir projects, including Gale (HTTP/3 Phoenix adapter, ~825K req/s on localhost), Crucible (multi-cloud provisioner), Zeiroh (FLAME overlay), and Orian (S3/S5 transfer). All published on Hex.pm with CI and docs.
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
- **Title:** Stacks HTTP/3 Configuration Guide
- **Amount:** $1,500 STX
- **Duration:** Weeks 1–3
- **Deliverables:** Production guide, TLS automation tips, reverse-proxy configs, CI validation

### Milestone 2
- **Title:** Stacks Ecosystem Benchmarks
- **Amount:** $1,500 STX
- **Duration:** Weeks 4–6
- **Deliverables:** Benchmark suite for Stacks API patterns, HTTP/3 vs HTTP/2 comparison, published results

### Milestone 3
- **Title:** Gale Stacks Adapter + Documentation
- **Amount:** $2,000 STX
- **Duration:** Weeks 7–8
- **Deliverables:** `:gale_stacks` Hex package, integration examples, blog post

---

## Disbursement
```
50% at Milestone 1 (Week 3)
50% at Milestone 3 (Week 8)
```
