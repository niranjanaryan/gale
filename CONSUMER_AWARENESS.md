# Gale Consumer Awareness

## Target Audience

| Segment | Who they are | Why they care |
|---------|-------------|---------------|
| Stacks API node operators | Run public `/v2/info`, `/v2/chain_info` | HTTP/3 cuts latency and improves mobile UX |
| Block explorer teams | Serve mobile wallet users | Faster page loads on cellular networks |
| Wallet backend developers | Cross-region API access | Eliminates TCP head-of-line blocking |
| sBTC relay operators | High-throughput status endpoints | 412× throughput with 7 parallel streams |

## Awareness Channels

### Stacks Ecosystem
- **Stacks Forum:** "Deploying a Stacks API Node with HTTP/3 using Gale"
- **Stacks Discord:** Q&A, demos, office hours
- **Stacks GitHub:** Issues, discussions, PRs

### Elixir Ecosystem
- **Elixir Forum:** "HTTP/3 in Elixir: benchmarks and production configs"
- **Hex.pm:** Package description, docs, changelogs
- **GitHub:** Issues, discussions, stars, forks

### Social Media
- **Twitter/X:** Benchmark screenshots, release announcements
- **Reddit r/elixir:** Cross-post tutorials
- **Hacker News:** Title + summary + link

## Content Strategy

### Blog Posts / Tutorials
1. **"Deploying a Stacks API Node with HTTP/3 using Gale"**
   - Drop-in config for existing Phoenix/Plug apps
   - TLS cert management with Let's Encrypt
   - Reverse-proxy tips for gradual HTTP/3 rollout
   - Target: Stacks API node operators

2. **"HTTP/3 Benchmarks for Stacks Infrastructure"**
   - `/v2/info`, `/v2/chain_info`, block explorer HTML, sBTC relay JSON
   - HTTP/3 vs HTTP/2 vs HTTP/1.1 comparison
   - Methodology and reproducibility
   - Target: Performance-conscious operators

3. **"Gale Stacks Adapter: Pre-tuned Configs for Common Patterns"**
   - `:gale_stacks` package overview
   - API node, wallet backend, sBTC relay presets
   - Integration examples
   - Target: Elixir developers building on Stacks

### Demo Videos
- **2 min:** Gale HTTP/3 benchmark screencast
- **5 min:** Full deployment guide for Stacks API node

### Benchmark Publications
- `benchmark/STACKS_BENCHMARKS.md` — HTTP/3 vs HTTP/2 results
- `GALE_STACKS.md` — Production-ready configs

## Adoption Metrics

| Metric | Baseline | 30-day target | 90-day target |
|--------|----------|---------------|---------------|
| Hex downloads | 0 | 200+ | 1,000+ |
| GitHub stars | 0 | 50+ | 200+ |
| Stacks Forum replies | 0 | 5+ | 20+ |
| Blog post views | 0 | 500+ | 2,000+ |
| Demo video views | 0 | 200+ | 1,000+ |

## Timeline

### Week 1
- [ ] Publish `GALE_STACKS.md` to HexDocs
- [ ] Post Stacks Forum tutorial
- [ ] Record benchmark video

### Week 2
- [ ] Post Elixir Forum thread
- [ ] Submit Reddit r/elixir cross-post
- [ ] Reach out to 5 Stacks API node operators

### Week 3-4
- [ ] Publish blog post
- [ ] Monitor and respond to feedback
- [ ] Update benchmarks with community results

## Key Messages

**For Stacks operators:**
> "HTTP/3 eliminates head-of-line blocking and reduces latency for mobile wallets and cross-region API access. Drop-in config for existing Phoenix/Plug apps."

**For Elixir developers:**
> "The only production-ready HTTP/3 adapter for Phoenix/Plug. Zig QPACK NIF provides 2.5× faster encoding. 412× throughput improvement with parallel streams."

## Competitive Positioning

| Competitor | Gap we fill |
|------------|-------------|
| Bandit/Cowboy | HTTP/3 support via Gale |
| Plug + Bandit | Drop-in HTTP/3 with Gale.PhoenixAdapter |
| Other HTTP/3 libs | Zig QPACK NIF for maximum performance |

**Our advantage:** Only drop-in Phoenix/Plug HTTP/3 adapter in Elixir with production-ready Stacks configs and benchmarks.

---

*This document is part of the Elixir Distributed Stack consumer awareness strategy.*
