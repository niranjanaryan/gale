# BLAKE3 vs XXH3 (and FNV-1a)

Eval for Gale / Ingot / Dusk. Zig NIFs: `blake3/1` (32-byte digest), `xxh3/1` (u64), `hash64/1` (FNV-1a, kept).

## Roles

| Hash | Crypto | Typical throughput | Use here |
| --- | --- | --- | --- |
| **BLAKE3** | Yes (256-bit, Merkle tree) | ~3–8 GB/s/core, scales across cores | S5 blob CIDs, S3 `x-amz-meta-blake3`, Iroh blob ids, integrity |
| **XXH3-64** | No | ~15–30 GB/s/core | Cluster routing, cache keys, hot checksums |
| **FNV-1a 64** | No | ~1–2 GB/s | Legacy `hash64/1` |
| SHA-256 | Yes | ~0.8–3 GB/s | AWS SigV4 payload hash only (S3 protocol requires it) |

## Decision

1. **Storage identity is BLAKE3.** S5 (and Iroh blobs) already use it. Same digest as `b3sum`. Collision-resistant; verified streaming via the Bao/Merkle layout later if we stream.
2. **Do not use XXH3 as a content id.** Fast and excellent for maps, not for adversarial or cross-trust storage.
3. **S3 stays location-addressed.** Key defaults to hex(BLAKE3). SigV4 still SHA-256. Metadata carries blake3 + xxh3.
4. **S5 is content-addressed.** CID `0x5b 0x82 0x1e` + 32-byte BLAKE3 + LEB128 size. HTTP `/s5/upload` and `/s5/blob/{hex}`.
5. **Keep FNV `hash64/1`** so existing cluster ticks do not change.

## S3 vs S5

- **S3**: any MinIO/AWS/R2 endpoint, SigV4 or unsigned. Fast PUT of opaque objects. Overlay CAS by hashing first.
- **S5**: CAS network (often on Iroh). Fetch by hash, verify every byte with BLAKE3. S3 can be an S5 *backend*, not the identity layer.

Zig `std.crypto.hash.Blake3` is slower than the official Rust/C+asm `b3sum` (~1 GB/s vs ~4 GB/s on some ARM). Good enough for Elixir NIF blobs; we can swap in C blake3 later if storage is the bottleneck.
