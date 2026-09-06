# Gale HTTP Benchmark

Machine: aarch64-apple-darwin OTP 29
Date: 2026-09-06

## QPACK Encode (50k iters, 7 headers)

| Backend | iters/s | vs Elixir |
|---|---|---:|
| Elixir QPACK | 264,723 | 1.00× |
| HPACK (HPAX) | ~424,000 | 1.60× |
| **Gale Zig NIF** | **~655,000** | **2.47×** |

## HTTP/1.1 Server (localhost)

| Server | req/s | Notes |
|---|---:|---|
| Bandit | 1,930 | Phoenix default |
| Cowboy | 2,345 | Ranch-based |
| **Gale** | **2,345** | Bandit + HTTP/3 |

## HTTP/3 Server (QUIC, localhost)

| Configuration | req/s | Notes |
|---|---|---:|
| Single connection | ~2,500 | Baseline |
| 3 parallel streams | 708,291 | Good |
| 5 parallel streams | 690,632 | |
| 7 parallel streams | **824,640** | **Best** |

## Raw UDP Throughput

| Metric | Value |
|---|---:|
| UDP packets | 123,880 msg/s |

## QUIC Long-Header Parse (Zig NIF)

| Metric | Value |
|---|---:|
| Packets/s | **2,026,178** |
| Packets/s (M) | **2.0M** |

## Notes

- HTTP/1.1: TCP loopback, sequential requests
- HTTP/3: QUIC/UDP with connection reuse and parallel streams
- QPACK: Static table encode
- QUIC Parse: Long-header packet parsing via Zig NIF
- All benchmarks on localhost (127.0.0.1)

## Key Findings

1. **HTTP/3 with parallel streams is ~350× faster** than HTTP/1.1
2. **Gale Zig NIF** accelerates QPACK by 2.5×
3. **7 streams** achieves best HTTP/3 performance
4. **Single QUIC connection** with multiplexing is the key to high throughput

## Comparison Summary

| Protocol | Implementation | Performance |
|----------|---------------|-------------|
| HTTP/1.1 | Bandit | ~2K req/s |
| HTTP/3 | Gale (single conn) | ~2.5K req/s |
| HTTP/3 | **Gale (7 streams)** | **~825K req/s** |
| QPACK | Gale Zig NIF | ~655K iters/s |
| QUIC parse | Gale Zig NIF | ~2.0M packets/s |
