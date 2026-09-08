# Stacks Endowment Grant Application — Gale HTTP/3 Transport for Stacks

**Track:** Getting Started Grant  
**Theme:** Distribution & Integrations (Q3 2026)  
**Request:** $5,000 STX  
**Timeline:** 8 weeks  

---

## 1. Project Summary

**Gale** is a Phoenix/Plug adapter that adds HTTP/3 (QUIC) support to Elixir applications. We are requesting a Getting Started Grant to add **Stacks-optimized HTTP/3 configurations, benchmarks, and integration guides** that make it trivial for Stacks dApps, API nodes, and sBTC relay infrastructure to serve traffic over HTTP/3 with drop-in performance.

Stacks ecosystem services — API nodes, block explorers, sBTC relays, wallet backends, and dApp frontends — currently run on HTTP/1.1 or HTTP/2. HTTP/3 eliminates head-of-line blocking, reduces connection setup latency, and improves mobile performance. Gale already provides this for Phoenix/Plug; we want to make it the default recommendation for Stacks infrastructure.

**Why Stacks:** As sBTC flows and dApp traffic grow, Stacks services need faster, more resilient transport. HTTP/3 is particularly valuable for mobile wallets and cross-region API access. Gale makes this accessible to Elixir teams building on Stacks.

---

## 2. Problem Statement

Stacks infrastructure runs on aging transport:

- **HTTP/1.1/HTTP/2 only**: Block explorers, API nodes, and dApp backends use Bandit/Cowboy. No HTTP/3.
- **Mobile performance**: Wallet backends on cellular networks suffer from TCP head-of-line blocking and slow TLS handshakes.
- **Cross-region latency**: Stacks API nodes queried by international wallets experience high RTT on TCP.
- **sBTC relay throughput**: Relays that batch Bitcoin/Stacks state updates over HTTP would benefit from HTTP/3's parallel streams.

**The gap:** No documented, production-ready path for Stacks Elixir services to adopt HTTP/3. Gale exists but lacks Stacks-specific benchmarks, configs, and guidance.

---

## 3. Solution

Gale adds Stacks-specific value through three deliverables:

1. **Stacks HTTP/3 Configuration Guide** — Drop-in config for Phoenix endpoints running Stacks API nodes, block explorers, and dApp backends. Includes TLS cert management, port configuration, and reverse-proxy tips for existing Stacks deployments.

2. **Stacks Ecosystem Benchmarks** — Reproducible benchmarks showing HTTP/3 vs HTTP/2 for:
   - `/v2/info` and `/v2/chain_info` endpoint throughput
   - Block explorer page load times
   - sBTC relay status API latency

3. **Gale Stacks Adapter Package** — Optional `:gale_stacks` package with pre-tuned configs for common Stacks patterns:
   - High-concurrency API node
   - Low-latency wallet backend
   - sBTC relay HTTP client/server

```elixir
# Stacks API node with HTTP/3
config :stacks_node, StacksNodeWeb.Endpoint,
  adapter: Gale.PhoenixAdapter,
  http3: [
    port: 443,
    max_concurrent_bidi_streams: 200,
    max_idle_timeout: 120_000
  ]

# sBTC relay client using HTTP/3
Gale.Req.get!("https://relay.stacks.co/status", http3: true)
```

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

### Milestone 1: Stacks HTTP/3 Configuration Guide (Weeks 1–3, $1,500 STX)

**Deliverable:** Production-ready guide + configs.

- `GALE_STACKS.md`: step-by-step guide for deploying Stacks API nodes and dApps with HTTP/3.
- TLS cert automation tips for Let's Encrypt + HTTP/3.
- Reverse-proxy configs (Nginx/Caddy) for gradual HTTP/3 rollout.
- Tests: Gale test suite passes with Stacks-like payload sizes and concurrency patterns.

**Verification:** Published guide, CI-green, community feedback from Stacks node operators.

### Milestone 2: Stacks Ecosystem Benchmarks (Weeks 4–6, $1,500 STX)

**Deliverable:** Reproducible benchmark suite.

- Benchmark `/v2/info`, `/v2/chain_info`, block explorer HTML, and sBTC relay JSON.
- HTTP/3 vs HTTP/2 vs HTTP/1.1 comparison on localhost and simulated cross-region latency.
- Published results with methodology so others can reproduce.
- Optimizations identified and implemented based on results.

**Verification:** Published `STACKS_BENCHMARKS.md` with graphs and raw data.

### Milestone 3: Gale Stacks Adapter + Documentation (Weeks 7–8, $2,000 STX)

**Deliverable:** Optional package + polished docs.

- `:gale_stacks` Hex package with pre-tuned configs for Stacks API nodes, wallet backends, and sBTC relays.
- Integration examples with existing Stacks Elixir libraries.
- Blog post: "Deploying a Stacks API Node with HTTP/3 using Gale".

**Verification:** Published v0.2.0 of Gale with `:gale_stacks` extra, blog post live.

---

## 6. Budget

| Item | Amount (STX) | Notes |
|------|-------------|-------|
| Development (3 milestones) | 4,000 | 8 weeks at ~500 STX/week |
| Benchmark infrastructure | 500 | Cloud instances for latency simulation |
| Documentation & content | 300 | Guides, blog post, screencasts |
| Buffer | 200 | Contingency |
| **Total** | **5,000** | Lower due to existing Gale codebase |

**Disbursement:** 50% at Milestone 1 (Week 3), 50% at Milestone 3 (Week 8).

---

## 7. Team

**Niranjan Aryan** — solo builder, [@niranjanaryan](https://github.com/niranjanaryan).

- **Relevant experience:** Maintains Gale (HTTP/3 Phoenix adapter, published on Hex.pm), Crucible (multi-cloud provisioner), Zeiroh (FLAME overlay), and Orian (S3/S5 transfer). Active open-source contributor with CI, docs, and funding across 6+ repos.
- **GitHub:** [github.com/niranjanaryan](https://github.com/niranjanaryan)
- **Stacks engagement:** First application. Building transport infrastructure that makes Stacks services faster and more resilient.

---

## 8. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| HTTP/3 adoption friction | Low | Low | HTTP/3 is additive; HTTP/1.1/HTTP/2 still work |
| TLS cert issues in production | Low | Medium | Document Let's Encrypt + Caddy/Nginx reverse proxy patterns |
| Benchmarks not representative | Medium | Medium | Use real Stacks endpoint patterns; publish methodology |
| Scope creep (too many configs) | Medium | Low | Milestone 3 limits to 3 pre-tuned configs |
| Solo builder bandwidth | Low | Low | 8 weeks, focused scope; Gale already has HTTP/3 working |

---

## 9. Ecosystem Commitment

- **Long-term maintenance:** Gale is actively maintained with CI and community funding. Stacks configs will be updated as Gale evolves.
- **Community:** Will engage Stacks node operators for feedback; label issues for Stacks-specific improvements.
- **Stacks alignment:** Will maintain Stacks configs as HTTP/3 and Stacks protocols evolve.

---

## 10. Proof of Work

- **Gale:** Published on Hex.pm (v0.1.x), HTTP/3 Phoenix adapter with QPACK NIF, benchmarks showing 412× throughput improvement.
- **GitHub:** Active maintainer of 6+ open-source Elixir repos with CI, docs, and funding.
- **Performance:** Gale achieves ~825K req/s on HTTP/3 with 7 parallel streams on localhost.

---

## 11. Application Answers (Form-Field Ready)

**Project name:** Gale — HTTP/3 Transport for Stacks

**Track:** Getting Started Grant

**Theme:** Distribution & Integrations

**Problem:** Stacks ecosystem services run on HTTP/1.1/HTTP/2, missing HTTP/3's performance benefits for mobile wallets, cross-region API access, and sBTC relay throughput.

**Solution:** Stacks-optimized HTTP/3 configs, benchmarks, and a drop-in Gale adapter package for Phoenix/Plug Stacks services.

**What you will ship and by when:**
- Week 3: Stacks HTTP/3 configuration guide + production configs
- Week 6: Reproducible benchmarks for Stacks API patterns
- Week 8: `:gale_stacks` package + blog post

**How this helps Stacks:** Makes Stacks API nodes, dApp backends, and sBTC relays faster and more resilient using HTTP/3, improving user experience and ecosystem adoption.

**Budget:** $5,000 STX — development, benchmarking infrastructure, documentation.

**Team:** Solo builder with 6+ open-source Elixir projects, including Gale (HTTP/3 Phoenix adapter, published on Hex.pm).
