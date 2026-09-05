//! QPACK static-table encoder matching the Zig NIF, used as a Rust
//! throughput baseline (process-local, no BEAM).

const STATIC: &[(&str, &str)] = &[
    (":authority", ""),
    (":path", "/"),
    ("age", "0"),
    ("content-disposition", ""),
    ("content-length", "0"),
    ("cookie", ""),
    ("date", ""),
    ("etag", ""),
    ("if-modified-since", ""),
    ("if-none-match", ""),
    ("last-modified", ""),
    ("link", ""),
    ("location", ""),
    ("referer", ""),
    ("set-cookie", ""),
    (":method", "CONNECT"),
    (":method", "DELETE"),
    (":method", "GET"),
    (":method", "HEAD"),
    (":method", "OPTIONS"),
    (":method", "POST"),
    (":method", "PUT"),
    (":scheme", "http"),
    (":scheme", "https"),
    (":status", "103"),
    (":status", "200"),
    (":status", "304"),
    (":status", "404"),
    (":status", "503"),
    ("accept", "*/*"),
    ("accept", "application/dns-message"),
    ("accept-encoding", "gzip, deflate, br"),
    ("accept-ranges", "bytes"),
    ("access-control-allow-headers", "cache-control"),
    ("access-control-allow-headers", "content-type"),
    ("access-control-allow-origin", "*"),
    ("cache-control", "max-age=0"),
    ("cache-control", "max-age=2592000"),
    ("cache-control", "max-age=604800"),
    ("cache-control", "no-cache"),
    ("cache-control", "no-store"),
    ("cache-control", "public, max-age=31536000"),
    ("content-encoding", "br"),
    ("content-encoding", "gzip"),
    ("content-type", "application/dns-message"),
    ("content-type", "application/javascript"),
    ("content-type", "application/json"),
    ("content-type", "application/x-www-form-urlencoded"),
    ("content-type", "image/gif"),
    ("content-type", "image/jpeg"),
    ("content-type", "image/png"),
    ("content-type", "text/css"),
    ("content-type", "text/html; charset=utf-8"),
    ("content-type", "text/plain"),
    ("content-type", "text/plain;charset=utf-8"),
    ("range", "bytes=0-"),
    ("strict-transport-security", "max-age=31536000"),
    ("strict-transport-security", "max-age=31536000; includesubdomains"),
    (
        "strict-transport-security",
        "max-age=31536000; includesubdomains; preload",
    ),
    ("x-content-type-options", "nosniff"),
    ("x-xss-protection", "1; mode=block"),
    (":status", "100"),
    (":status", "204"),
    (":status", "206"),
    (":status", "302"),
    (":status", "400"),
    (":status", "403"),
    (":status", "421"),
    (":status", "425"),
    (":status", "500"),
    ("accept-language", ""),
    ("access-control-allow-credentials", "FALSE"),
    ("access-control-allow-credentials", "TRUE"),
    ("access-control-allow-headers", "*"),
    ("access-control-allow-methods", "get"),
    ("access-control-allow-methods", "get, post, options"),
    ("access-control-allow-methods", "options"),
    ("access-control-expose-headers", "content-length"),
    ("access-control-request-headers", "content-type"),
    ("access-control-request-method", "get"),
    ("access-control-request-method", "post"),
    ("alt-svc", "clear"),
    ("authorization", ""),
    (
        "content-security-policy",
        "script-src 'none'; object-src 'none'; base-uri 'none'",
    ),
    ("early-data", "1"),
    ("expect-ct", ""),
    ("forwarded", ""),
    ("if-range", ""),
    ("origin", ""),
    ("purpose", "prefetch"),
    ("server", ""),
    ("timing-allow-origin", "*"),
    ("upgrade-insecure-requests", "1"),
    ("user-agent", ""),
    ("x-forwarded-for", ""),
    ("x-frame-options", "deny"),
    ("x-frame-options", "sameorigin"),
];

fn encode_int(buf: &mut Vec<u8>, n: usize, prefix_bits: u8, first_mask: u8) {
    let max = (1usize << prefix_bits) - 1;
    if n < max {
        buf.push(first_mask | n as u8);
        return;
    }
    buf.push(first_mask | max as u8);
    let mut rest = n - max;
    while rest >= 128 {
        buf.push(((rest % 128) as u8) | 128);
        rest /= 128;
    }
    buf.push(rest as u8);
}

fn qpack_encode(headers: &[(&str, &str)]) -> Vec<u8> {
    let mut buf = Vec::with_capacity(64);
    buf.push(0);
    buf.push(0);
    for (name, value) in headers {
        if let Some(idx) = STATIC.iter().position(|(n, v)| n == name && v == value) {
            encode_int(&mut buf, idx, 6, 0xC0);
            continue;
        }
        if let Some(idx) = STATIC.iter().position(|(n, _)| n == name) {
            encode_int(&mut buf, idx, 4, 0x50);
            encode_int(&mut buf, value.len(), 7, 0);
            buf.extend_from_slice(value.as_bytes());
            continue;
        }
        encode_int(&mut buf, name.len(), 3, 0x20);
        buf.extend_from_slice(name.as_bytes());
        encode_int(&mut buf, value.len(), 7, 0);
        buf.extend_from_slice(value.as_bytes());
    }
    buf
}

fn main() {
    let n: u64 = std::env::args()
        .nth(1)
        .and_then(|s| s.parse().ok())
        .unwrap_or(200_000);
    let headers = [
        (":method", "GET"),
        (":scheme", "https"),
        (":path", "/"),
        (":authority", "localhost"),
        ("accept", "*/*"),
        ("content-type", "application/json"),
        ("user-agent", "h3_nif_rust"),
    ];
    let start = std::time::Instant::now();
    let mut last_len = 0usize;
    for _ in 0..n {
        last_len = qpack_encode(&headers).len();
    }
    let elapsed = start.elapsed().as_secs_f64();
    let ips = n as f64 / elapsed;
    println!("rust_qpack_encode iters={n} last_len={last_len} ips={ips:.0} elapsed_s={elapsed:.4}");
}
