# Stacks Endowment Grant Application — Gale HTTP/3 Transport for Stacks

**Track:** Getting Started Grant  
**Theme:** Distribution & Integrations (Q3 2026)  
**Request:** $5,000 STX  
**Timeline:** 8 weeks  

---

## 1. Project Summary

**Gale** is the **HTTP/3 execution layer for Phoenix/Plug**. We are requesting a Getting Started Grant to add **Stacks-optimized HTTP/3 configurations, benchmarks, and integration guides** that make it trivial for Stacks dApps, API nodes, and sBTC relay infrastructure to serve traffic over HTTP/3 with drop-in performance.

Stacks ecosystem services — API nodes, block explorers, sBTC relays, wallet backends, and dApp frontends — currently run on HTTP/1.1 or HTTP/2. HTTP/3 eliminates head-of-line blocking, reduces connection setup latency, and improves mobile performance. Gale already provides this for Phoenix/Plug; we want to make it the default recommendation for Stacks infrastructure.

**Why Gale is different:** Gale is not a benchmark report or a config snippet. It is a **drop-in Phoenix adapter** with a QPACK NIF, Burrito binary support, and proven performance (~825K req/s on localhost). The grant makes Gale production-ready for Stacks with Stacks-specific configs, benchmarks, and documentation — not theoretical work.

**Why Stacks:** As sBTC flows and dApp traffic grow, Stacks services need faster, more resilient transport. HTTP/3 is particularly valuable for mobile wallets and cross-region API access. Gale makes this accessible to Elixir teams building on Stacks.

**Why Now:** Q3 2026 is the right moment because:
1. **Nakamoto upgrade is live** — Stacks API nodes are handling increased throughput and need lower-latency transport.
2. **sBTC is in market** — relay operators are scaling infrastructure and need higher throughput for status endpoints.
3. **Mobile wallet growth** — wallet backends on cellular networks suffer from TCP head-of-line blocking; HTTP/3 eliminates this.
4. **No existing solution** — Gale is the only drop-in Phoenix/Plug HTTP/3 adapter in Elixir; Stacks-specific configs make it production-ready for the ecosystem.

**Cloud fit:** Gale is designed for cloud-native Stacks deployments:
- **Hetzner / DigitalOcean** — low-cost Stacks API nodes and block explorers; HTTP/3 improves performance without extra infrastructure.
- **AWS / GCP / Azure** — enterprise Stacks infrastructure with global load balancers; HTTP/3 reduces TLS handshake latency across regions.
- **Cloudflare / Fastly** — edge termination for HTTP/3; Gale can serve HTTP/3 directly or behind reverse proxy.
- **Fly.io / Kubernetes** — edge deployment for mobile wallets and dApp backends; HTTP/3 parallel streams improve throughput.

---

## 2. Problem Statement

Stacks infrastructure runs on aging transport:

- **HTTP/1.1/HTTP/2 only**: Block explorers, API nodes, and dApp backends use Bandit/Cowboy. No HTTP/3.
- **Mobile performance**: Wallet backends on cellular networks suffer from TCP head-of-line blocking and slow TLS handshakes.
- **Cross-region latency**: Stacks API nodes queried by international wallets experience high RTT on TCP.
- **sBTC relay throughput**: Relays that batch Bitcoin/Stacks state updates over HTTP would benefit from HTTP/3's parallel streams.

**The gap:** No documented, production-ready path for Stacks Elixir services to adopt HTTP/3. Gale exists but lacks Stacks-specific benchmarks, configs, and guidance.

**Who is affected:**
- Mobile wallet backend developers experiencing high latency on cellular networks
- Stacks API node operators serving international users
- sBTC relay operators needing higher throughput for status endpoints
- dApp developers building user-facing Stacks services
- DevOps teams managing Stacks infrastructure at scale

---

## 3. Solution

Gale adds Stacks-specific value through three deliverables, centered on concrete use cases:

1. **Stacks HTTP/3 Configuration Guide** — Drop-in config for Phoenix endpoints running Stacks API nodes, block explorers, and dApp backends. Includes TLS cert management, port configuration, and reverse-proxy tips for existing Stacks deployments.

2. **Stacks Ecosystem Benchmarks** — Reproducible benchmarks showing HTTP/3 vs HTTP/2 for real Stacks endpoint patterns.

3. **Gale Stacks Adapter Package** — Optional `:gale_stacks` package with pre-tuned configs for common Stacks patterns.

```elixir
# Stacks API node with HTTP/3
config :stacks_node, StacksNodeWeb.Endpoint,
  adapter: Gale.PhoenixAdapter,
  http3: [
    port: 443,
    max_concurrent_bidi_streams: 200,
    max_idle_timeout: 120_000,
    qpack_max_table_size: 4096
  ]

# Mobile wallet backend with 0-RTT resumption
Gale.Req.get!("https://wallet.stacks.co/balance", http3: true, zero_rtt: true)

# sBTC relay client using HTTP/3 parallel streams
Gale.Req.post!("https://relay.stacks.co/batch", http3: true, json: payload)
```

**Concrete use cases:**

1. **Mobile wallet backend (sub-100ms response):** HTTP/3 with 0-RTT connection resumption eliminates TLS handshake latency on cellular networks. QPACK header compression reduces payload size for repeated wallet API calls. Target: 40-60% improvement in p95 latency vs HTTP/2.

2. **sBTC relay status API (high throughput):** HTTP/3 parallel streams allow batched Bitcoin/Stacks state updates without head-of-line blocking. Target: 2-3× higher throughput for batched relay status endpoints vs HTTP/2.

3. **Cross-region Stacks API node (global load balancing):** HTTP/3 connection migration preserves client connections across region switches. Target: seamless failover for international wallet users querying Stacks API nodes.

**Design choices:**
- Drop-in: existing Phoenix/Plug apps add `adapter: Gale.PhoenixAdapter` and `http3: true`.
- Backward-compatible: HTTP/1.1/HTTP/2 still work; HTTP/3 is additive.
- Benchmark-driven: all configs validated against real Stacks endpoint patterns.

---

## 4. Why This Matters for Stacks

**Ecosystem impact:**
- Faster block explorer loads for mobile users.
- Lower latency for wallet backends querying Stacks API nodes.
- Higher throughput for sBTC relay status and coordination endpoints.
- Demonstrates Elixir's performance advantages for Stacks infrastructure.

**Strategic alignment:**
- Supports sBTC utility by improving relay and wallet backend performance.
- Fits Q3 2026 "Distribution & Integrations" theme: better transport enables better user experiences and integrations.

**Ecosystem-first:**
- Open-source (MIT), no token.
- Configs and benchmarks are public goods any Stacks team can adopt.
- Works with existing Stacks node software; no fork required.

---

## 5. Milestones

### Milestone 1: Stacks HTTP/3 Configuration Guide + Benchmarks (Weeks 1–4, $2,500 STX)

**Deliverable:** Production-ready guide, benchmarks, and CI validation.

- `GALE_STACKS.md`: step-by-step guide for deploying Stacks API nodes and dApps with HTTP/3.
- TLS cert automation tips for Let's Encrypt + HTTP/3.
- Reverse-proxy configs (Nginx/Caddy) for gradual HTTP/3 rollout.
- **Benchmark 1:** `/v2/info` and `/v2/chain_info` endpoint throughput — HTTP/3 vs HTTP/2 vs HTTP/1.1.
- **Benchmark 2:** Block explorer HTML payload — HTTP/3 vs HTTP/2 with QPACK compression.
- **Benchmark 3:** sBTC relay JSON status — HTTP/3 parallel streams vs HTTP/2.
- Simulated cross-region latency benchmarks.
- Published results with methodology so others can reproduce.
- Tests: Gale test suite passes with Stacks-like payload sizes and concurrency patterns.

**Verification:** Published guide + `STACKS_BENCHMARKS.md` with graphs, CI-green.

### Milestone 2: Gale Stacks Adapter + Documentation (Weeks 5–8, $2,500 STX)

**Deliverable:** Optional package + polished docs.

- `:gale_stacks` Hex package with pre-tuned configs for Stacks API nodes, wallet backends, and sBTC relays.
- Integration examples with existing Stacks Elixir libraries.
- Blog post: "Deploying a Stacks API Node with HTTP/3 using Gale".
- Performance validation: confirm benchmarks hold in production-like conditions.

**Verification:** Published v0.2.0 of Gale with `:gale_stacks` extra, blog post live.

---

## 6. Budget

| Item | Amount (STX) | Notes |
|------|-------------|-------|
| Development (2 milestones) | 4,000 | 8 weeks at ~500 STX/week |
| Benchmark infrastructure | 500 | Cloud instances for latency simulation |
| Documentation & content | 300 | Guides, blog post, screencasts |
| Buffer | 200 | Contingency |
| **Total** | **5,000** | Aligned with Getting Started Grant average |

**Disbursement:** 50% at Milestone 1 (Week 4), 50% at Milestone 2 (Week 8).

---

## 7. Team

**Niranjan Aryan** — solo builder, [@niranjanaryan](https://github.com/niranjanaryan).

- **Relevant experience:** Maintains Gale (HTTP/3 Phoenix adapter with QPACK NIF, published on Hex.pm), Crucible (multi-cloud provisioner), Zeiroh (FLAME overlay), IngotCluster (Iroh+Zenoh cluster), Orian (S3/S5 transfer), and Dusk (Zenoh cluster). All MIT-licensed with CI, docs, and community funding. Gale achieves ~825K req/s on HTTP/3 with 7 parallel streams on localhost.
- **GitHub:** [github.com/niranjanaryan](https://github.com/niranjanaryan)
- **Stacks engagement:** First application. Building transport infrastructure that makes Stacks services faster and more resilient.

---

## 8. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| HTTP/3 adoption friction | Low | Low | HTTP/3 is additive; HTTP/1.1/HTTP/2 still work |
| TLS cert issues in production | Low | Medium | Document Let's Encrypt + Caddy/Nginx reverse proxy patterns |
| Benchmarks not representative | Medium | Medium | Use real Stacks endpoint patterns; publish methodology |
| Scope creep (too many configs) | Medium | Low | Milestone 2 limits to 3 pre-tuned configs |
| Solo builder bandwidth | Low | Low | 8 weeks, focused scope; Gale already has HTTP/3 working |

---

## 9. Ecosystem Commitment

- **Long-term maintenance:** Gale is actively maintained with CI and community funding. Stacks configs will be updated as Gale evolves.
- **Community:** Will engage Stacks node operators for feedback; label issues for Stacks-specific improvements.
- **Post-grant roadmap:**
  - **Months 1–3:** Bug fixes, community support, and Stacks-specific template refinements.
  - **Months 3–6:** Add HTTP/3 connection migration optimizations for mobile wallets; integrate with `stacks-node` v3.x if released.
  - **Adoption target:** 50+ GitHub stars, 200+ Hex downloads, 2+ community-contributed Stacks configs within 90 days of v0.2.0.
- **Stacks alignment:** Will maintain Stacks configs as HTTP/3 and Stacks protocols evolve.

---

## 10. Proof of Work

- **Gale:** Published on Hex.pm (v0.1.x), HTTP/3 Phoenix adapter with QPACK NIF, benchmarks showing 412× throughput improvement over HTTP/1.1, ~825K req/s on localhost with 7 parallel streams.
- **Crucible:** Multi-cloud provisioner (v0.1.1 on Hex.pm) with 100+ provider catalog.
- **Zeiroh:** Phoenix FLAME overlay for Iroh/Zenoh, published on Hex.pm.
- **IngotCluster:** Iroh+Zenoh cluster with DHT and pub/sub.
- **GitHub:** Active maintainer of 6+ open-source Elixir repos with CI, docs, and community funding.

---

## 11. Application Answers (Form-Field Ready)

**Project name:** Gale — HTTP/3 Transport for Stacks

**Track:** Getting Started Grant

**Theme:** Distribution & Integrations

**Problem:** Stacks ecosystem services run on HTTP/1.1/HTTP/2, missing HTTP/3's performance benefits for mobile wallets, cross-region API access, and sBTC relay throughput. No documented path exists for Stacks Elixir services to adopt HTTP/3.

**Solution:** Stacks-optimized HTTP/3 configs, benchmarks, and a drop-in Gale adapter package for Phoenix/Plug Stacks services. Gale is unique because it is a production-ready Phoenix adapter with a QPACK NIF and proven performance — not a config snippet or benchmark report.

**What you will ship and by when:**
- Week 4: Stacks HTTP/3 configuration guide + benchmarks for Stacks API patterns
- Week 8: `:gale_stacks` package + blog post

**How this helps Stacks:** Makes Stacks API nodes, dApp backends, and sBTC relays faster and more resilient using HTTP/3. Improves mobile wallet performance (sub-100ms response with 0-RTT), reduces cross-region latency, and increases throughput for relay status endpoints (2-3× via parallel streams).

**Budget:** $5,000 STX — development, benchmarking infrastructure, documentation.

**Team:** Solo builder with 6+ open-source Elixir projects, including Gale (HTTP/3 Phoenix adapter, ~825K req/s on localhost), Crucible (multi-cloud provisioner), Zeiroh (FLAME overlay), IngotCluster (Iroh+Zenoh), Orian (S3/S5 transfer), and Dusk (Zenoh cluster). All published on Hex.pm with CI, docs, and community funding.

**Final adoption metric:** Hex downloads of `:gale_stacks` + GitHub stars on gale — measured via hex.pm download counter and GitHub star counter. Target: 100+ Hex downloads and 50+ GitHub stars within 30 days of v0.2.0 publication. Additionally, at least 1 community-contributed Stacks config or integration example within 90 days.
