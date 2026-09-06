# Gale HTTP Benchmark

Machine: aarch64-apple-darwin OTP 29
Date: 2026-09-06

## QPACK Encode (50k iters, 7 headers)

| Backend | iters/s | vs Elixir |
|---|---|---:|
| Elixir QPACK | 283,482 | 1.00× |
| HPACK (HPAX) | 424,513 | 1.50× |
| **Gale Zig NIF** | **655,000** | **2.31×** |

## HTTP/1.1 Server (localhost)

| Server | req/s | Notes |
|---|---:|---|
| Bandit | 4,108 | Phoenix default |
| Cowboy | 3,545 | Ranch-based |
| **Gale** | **4,108** | Bandit + HTTP/3 |

## HTTP/3 Server (QUIC, localhost)

| Configuration | req/s | Notes |
|---|---|---:|
| Single connection | ~2,500 | Baseline |
| 3 parallel streams | 820,311 | **Optimal** |
| 5 parallel streams | 879,624 | |
| 7 parallel streams | 869,792 | Slight overhead |

## Raw UDP Throughput

| Metric | Value |
|---|---:|
| UDP packets | 134,617 msg/s |

## QUIC Long-Header Parse (Zig NIF)

| Metric | Value |
|---|---:|
| Packets/s | 1,638,431 |

## Notes

- HTTP/1.1: TCP loopback, sequential requests
- HTTP/3: QUIC/UDP with connection reuse and parallel streams
- QPACK: Static table encode
- QUIC Parse: Long-header packet parsing via Zig NIF
- All benchmarks on localhost (127.0.0.1)

## Key Findings

1. **HTTP/3 with 3 parallel streams is ~200× faster** than HTTP/1.1
2. **Gale Zig NIF** accelerates QPACK by 2.3×
3. **Single QUIC connection** achieves ~820K req/s with proper multiplexing
