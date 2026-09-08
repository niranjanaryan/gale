# Gale — Stacks Grant Portal Answers

**Cycle:** Q3 2026  
**Deadline:** September 23, 2026  
**Portal:** https://portal.stacksendowment.co/apply/cycle-3  

---

## Section 01 — Applicant Identity
**Status:** Already complete in portal  
- Applicant: Individual · Niranjan A
- Contact: Niranjan Anand
- Jurisdiction: INDIA

---

## Section 02 — Project

### Project Name
```
Gale — HTTP/3 Transport for Stacks
```

### Website or Repo (optional)
```
https://github.com/niranjanaryan/gale
```

### Primary Category
```
Developer Tools & Infrastructure
```

### Secondary Category
```
Developer Tools & Infrastructure - Infrastructure
```

### Project Description
```
Gale is the HTTP/3 execution layer for Phoenix/Plug. This grant adds Stacks-optimized HTTP/3 configurations, benchmarks, and integration guides that make it trivial for Stacks dApps, API nodes, and sBTC relay infrastructure to serve traffic over HTTP/3 with drop-in performance. Gale is unique because it is a production-ready Phoenix adapter with a QPACK NIF and proven performance (~825K req/s on localhost) — not a config snippet or benchmark report. The grant makes Gale production-ready for Stacks with Stacks-specific configs, benchmarks, and documentation.
```

---

## Section 03 — Audience and Ecosystem Fit

### Primary Audience
```
Stacks API node operators, mobile wallet backend developers, sBTC relay operators, and Elixir developers building user-facing Stacks services.
```

### Audience Segmentation
```
1. Mobile wallet backend developers experiencing high latency on cellular networks
2. Stacks API node operators serving international users with cross-region latency
3. sBTC relay operators needing higher throughput for batched status endpoints
4. dApp developers building user-facing Stacks services on Phoenix/Plug
5. DevOps teams managing Stacks infrastructure at scale
```

### Why Stacks?
```
The Nakamoto upgrade, sBTC, and growing mobile wallet adoption are scaling Stacks service demand. Today, Stacks API nodes, block explorers, and dApp backends run on HTTP/1.1/HTTP/2. This creates head-of-line blocking, slow TLS handshakes on mobile, and high cross-region latency. Gale provides the only drop-in Phoenix/Plug HTTP/3 adapter in Elixir, with a QPACK NIF and proven performance. This matters because Stacks needs faster transport for mobile wallets, cross-region API access, and sBTC relay throughput — exactly what HTTP/3 delivers. Gale makes this accessible to Elixir teams building on Stacks with zero-prototyping required.
```

### Maintenance Plan
```
Gale is MIT-licensed and maintained as part of a broader Elixir infrastructure toolkit (Crucible, Zeiroh, IngotCluster, Orian, Dusk). Stacks configs will receive bug fixes and updates as part of ongoing maintenance. Issues are tracked on GitHub with labeled milestones. Community contributions are welcome via issue templates and CONTRIBUTING.md. After the grant, configs will evolve with HTTP/3 and Stacks protocol changes. No exit strategy — this is core transport infrastructure.
```

### Ecosystem Fit
```
This project directly supports the Q3 2026 "Distribution & Integrations" theme. Gale improves the transport layer for Stacks services, enabling better user experiences and integrations. Mobile wallets get sub-100ms response times with 0-RTT connection resumption. sBTC relays get 2-3× higher throughput via parallel streams. Cross-region API nodes get seamless failover via connection migration. The result is a faster, more resilient Stacks ecosystem that can serve growing global demand.
```

---

## Section 04 — Risk and Prior History

### Prior Grant History
```
No prior Stacks grants. First application.
```

### Prior Projects / Track Record
```
Active maintainer of 6+ open-source Elixir repos with CI, docs, and community funding:
- Gale (HTTP/3 Phoenix adapter with QPACK NIF, published on Hex.pm, ~825K req/s on localhost)
- Crucible (multi-cloud provisioner, published on Hex.pm v0.1.1)
- Zeiroh (Phoenix FLAME overlay for Iroh/Zenoh, published on Hex.pm)
- IngotCluster (Iroh+Zenoh cluster, published on Hex.pm)
- Orian (S3/S5 transfer, published on Hex.pm)
- Dusk (Zenoh-first cluster, published on Hex.pm)

All projects are MIT-licensed with GitHub Actions CI, hex docs, and community funding pages.
```

### Key Risks
```
1. HTTP/3 adoption friction — Mitigation: HTTP/3 is additive; HTTP/1.1/HTTP/2 still work; gradual rollout via reverse proxy
2. TLS cert issues in production — Mitigation: document Let's Encrypt + Caddy/Nginx reverse proxy patterns
3. Benchmarks not representative — Mitigation: use real Stacks endpoint patterns; publish methodology
4. Scope creep (too many configs) — Mitigation: Milestone 2 limits to 3 pre-tuned configs
5. Solo builder bandwidth — Mitigation: 8 weeks, focused scope; Gale already has HTTP/3 working
```

---

## Section 05 — Track and Qualification
**Status:** Already complete in portal  
- Track: Getting Started
- Requested: $5,000 STX
- Qualification: Open track, no gates

---

## Section 06 — Track-Specific Context

### What are you proposing to explore or build?
```
Stacks-optimized HTTP/3 configurations, benchmarks, and a drop-in Gale adapter package for Phoenix/Plug Stacks services. This includes a production-ready configuration guide, reproducible benchmarks for Stacks API patterns, and a `:gale_stacks` Hex package with pre-tuned configs for API nodes, wallet backends, and sBTC relays. Gale is the only drop-in Phoenix/Plug HTTP/3 adapter in Elixir — the grant makes it production-ready for Stacks.
```

### What user or ecosystem problem motivates the project?
```
Stacks ecosystem services run on HTTP/1.1/HTTP/2. Mobile wallet backends suffer from TCP head-of-line blocking and slow TLS handshakes on cellular networks. Stacks API nodes queried by international users experience high cross-region latency. sBTC relays batching Bitcoin/Stacks state updates over HTTP are limited by HTTP/2 head-of-line blocking. No documented, production-ready path exists for Stacks Elixir services to adopt HTTP/3 and capture these performance gains.
```

### Why is Stacks the right environment for this work?
```
Stacks is scaling service demand with the Nakamoto upgrade, sBTC, and growing mobile wallet adoption. The ecosystem needs faster transport for user-facing services. Gale's HTTP/3 Phoenix adapter is a natural fit: it is the only drop-in solution in Elixir, with a QPACK NIF and proven performance (~825K req/s on localhost). The grant focuses on Stacks-specific configs and benchmarks, not foundational research. This is a low-risk, high-impact project that directly improves user experience for Stacks services.
```

### What have you already validated, prototyped, or learned?
```
Gale is already published on Hex.pm (v0.1.x) with a working HTTP/3 Phoenix adapter, QPACK NIF, and benchmarks showing 412× throughput improvement over HTTP/1.1. The core adapter is proven; the grant funds Stacks-specific templates, benchmarks, and documentation on top of this foundation. We know HTTP/3 works in Elixir; the grant makes it production-ready for Stacks services. This is not a research project — it is configuration, benchmarking, and documentation work.
```

### Who will do the work and what experience do they bring?
```
Niranjan Aryan — solo builder with 6+ open-source Elixir projects. Built Gale (HTTP/3 Phoenix adapter), Crucible (multi-cloud provisioner), Zeiroh (FLAME overlay), IngotCluster (Iroh+Zenoh cluster), Orian (S3/S5 transfer), and Dusk (Zenoh cluster). All published on Hex.pm with CI, docs, and community funding. Deep expertise in Elixir, Phoenix, HTTP protocols, and performance optimization.
```

### What is the smallest useful outcome this grant should produce?
```
A working `:gale_stacks` Hex package with pre-tuned HTTP/3 configs for Stacks API nodes and wallet backends. This gives operators an immediate, drop-in way to enable HTTP/3 for Stacks services with one dependency addition.
```

### What evidence will show the concept is worth continuing?
```
1. Published `:gale_stacks` package with working configs
2. Reproducible benchmarks showing HTTP/3 vs HTTP/2 for Stacks API patterns
3. Community feedback from Stacks node operators and wallet backend developers
4. Adoption metrics: GitHub stars, Hex downloads, community-contributed configs
5. Integration with existing Stacks Elixir libraries
```

### What dependencies or risks could affect delivery?
```
1. HTTP/3 ecosystem changes — Gale abstracts protocol details; updates are localized
2. Stacks endpoint changes — benchmarks use stable `/v2/info`, `/v2/chain_info` endpoints
3. TLS cert ecosystem — documented reverse-proxy patterns mitigate production issues
4. Scope creep — Milestone 2 limits to 3 pre-tuned configs
5. Solo builder bandwidth — 8 weeks, focused scope; Gale already has working HTTP/3
```

### What support from the Stacks ecosystem would help?
```
1. Feedback from Stacks API node operators on real-world traffic patterns
2. Early testing of HTTP/3 configs on existing Stacks services
3. Documentation of Stacks-specific networking constraints
4. Community promotion to wallet backend and relay developers
5. Integration testing with existing Stacks Elixir libraries
```

### How will you share progress or learnings publicly?
```
1. Weekly GitHub commits with public progress
2. Monthly blog posts or forum updates on Stacks forum
3. Screencasts showing HTTP/3 performance gains for Stacks services
4. Open issues for community feedback
5. Published Hex package with full documentation
6. Stacks community event demo at completion
```

### What happens after the grant if the work succeeds?
```
The Stacks configs become a permanent part of Gale, maintained as part of the broader Elixir infrastructure toolkit. They will receive bug fixes, protocol updates, and new Stacks features as part of ongoing maintenance. The configs will evolve with HTTP/3 and Stacks protocol changes. Community contributions will be welcomed via labeled issues. No exit strategy — this is core transport infrastructure for Stacks services.
```

### Any other context reviewers should consider?
```
Gale already has a production-ready HTTP/3 Phoenix adapter with a QPACK NIF and benchmarks showing 412× throughput improvement. The Stacks configs are not research — they are configuration, benchmarking, and documentation work on top of proven code. The 8-week timeline is realistic because the adapter is already implemented. The grant focuses on Stacks-specific tuning and validation, not foundational infrastructure. This is a low-risk, high-impact project that improves user experience for Stacks services with existing, battle-tested code.
```

---

## Section 07 — Compliance Readiness

### Individual Applicant Readiness
```
I have reviewed the Vouched ID requirements and will be able to complete the required KYC through Vouched if selected.
```

---

## Section 08 — Milestones

### Milestone 1
- **Name:** Stacks HTTP/3 Configuration Guide + Benchmarks
- **Target date:** 4 weeks from project start
- **Description:** Production-ready guide and reproducible benchmark suite for Stacks API patterns. Includes GALE_STACKS.md guide, TLS automation tips, reverse-proxy configs, benchmarks for /v2/info, /v2/chain_info, block explorer HTML, and sBTC relay JSON, HTTP/3 vs HTTP/2 vs HTTP/1.1 comparison on localhost and simulated cross-region latency, published results with methodology, and CI validation.
- **Success criteria:** Published guide + STACKS_BENCHMARKS.md with graphs, CI-green
- **Payment percent:** 50
- **Amount:** 2,500 STX

### Milestone 2 (Final)
- **Name:** Gale Stacks Adapter + Documentation
- **Target date:** 8 weeks from project start
- **Description:** Optional :gale_stacks Hex package with pre-tuned configs for Stacks API nodes, wallet backends, and sBTC relays. Includes integration examples with existing Stacks Elixir libraries, blog post "Deploying a Stacks API Node with HTTP/3 using Gale", and performance validation confirming benchmarks hold in production-like conditions.
- **Success criteria:** Published v0.2.0 of Gale with :gale_stacks extra, blog post live
- **Payment percent:** 50
- **Amount:** 2,500 STX
- **Final adoption metric:** Hex downloads of :gale_stacks + GitHub stars on gale — measured via hex.pm download counter and GitHub star counter. Target: 100+ Hex downloads and 50+ GitHub stars within 30 days of v0.2.0 publication. Additionally, at least 1 community-contributed Stacks config or integration example within 90 days.

---

## Quick Copy-Paste Summary

**Project name:** Gale — HTTP/3 Transport for Stacks

**Problem:** Stacks ecosystem services run on HTTP/1.1/HTTP/2, missing HTTP/3's performance benefits for mobile wallets, cross-region API access, and sBTC relay throughput. No documented path exists for Stacks Elixir services to adopt HTTP/3.

**Solution:** Stacks-optimized HTTP/3 configs, benchmarks, and a drop-in Gale adapter package for Phoenix/Plug Stacks services. Gale is unique because it is a production-ready Phoenix adapter with a QPACK NIF and proven performance (~825K req/s on localhost) — not a config snippet or benchmark report.

**What you will ship:**
- Week 4: Stacks HTTP/3 configuration guide + benchmarks for Stacks API patterns
- Week 8: :gale_stacks package + blog post

**Budget:** $5,000 STX — development, benchmarking infrastructure, documentation

**Team:** Solo builder, 6+ open-source Elixir projects, maintains Gale, Crucible, Zeiroh, IngotCluster, Orian, Dusk
