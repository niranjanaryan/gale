use std::net::{TcpListener, TcpStream};
use std::io::{Read, Write, BufRead};
use std::time::Instant;

// QPACK Static Table (RFC 9204)
struct StaticEntry(&'static str, &'static str);
const STATIC_TABLE: &[StaticEntry] = &[
    StaticEntry(":authority", ""),
    StaticEntry(":path", "/"),
    StaticEntry(":method", "GET"),
    StaticEntry(":method", "POST"),
    StaticEntry(":scheme", "https"),
    StaticEntry(":status", "200"),
    StaticEntry(":status", "404"),
    StaticEntry("content-type", "application/json"),
    StaticEntry("content-type", "text/plain"),
    StaticEntry("accept", "*/*"),
    StaticEntry("user-agent", ""),
];

fn find_static_idx(name: &str, value: &str) -> Option<usize> {
    STATIC_TABLE.iter().position(|e| e.0 == name && e.1 == value)
}

// HTTP/1.1 Response
fn http1_response() -> String {
    "HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\nContent-Length: 2\r\n\r\nok".to_string()
}

// HTTP/1.1 Handler
fn handle_http1(mut stream: TcpStream) -> std::io::Result<()> {
    let mut buffer = [0u8; 1024];
    stream.read(&mut buffer)?;
    let response = http1_response();
    stream.write_all(response.as_bytes())?;
    stream.flush()
}

// HTTP/1.1 Server
fn serve_http1(port: u16, count: usize) -> f64 {
    let listener = TcpListener::bind(format!("127.0.0.1:{}", port)).unwrap();
    listener.set_nonblocking(true).unwrap();
    
    let start = Instant::now();
    let mut handled = 0;
    
    for stream in listener.incoming() {
        match stream {
            Ok(stream) => {
                handle_http1(stream).ok();
                handled += 1;
                if handled >= count { break; }
            }
            Err(_) => continue,
        }
    }
    
    let elapsed = start.elapsed().as_secs_f64();
    count as f64 / elapsed
}

// Simple frame writer
fn write_varint(buf: &mut Vec<u8>, n: u64) {
    if n <= 63 {
        buf.push(n as u8);
    } else if n <= 16383 {
        buf.push(0x40 | ((n >> 8) as u8));
        buf.push((n & 0xff) as u8);
    } else {
        buf.push(0x80 | ((n >> 24) as u8));
        buf.push((n >> 16) as u8);
        buf.push((n >> 8) as u8);
        buf.push(n as u8);
    }
}

// H1 Response with keep-alive
fn h1_benchmark(port: u16, n: usize) -> f64 {
    std::thread::spawn(move || serve_http1(port, n));
    std::thread::sleep(std::time::Duration::from_millis(50));
    
    let start = Instant::now();
    let mut count = 0;
    
    for _ in 0..n {
        if let Ok(mut stream) = TcpStream::connect(format!("127.0.0.1:{}", port)) {
            stream.write_all(b"GET / HTTP/1.1\r\nHost: localhost\r\n\r\n").ok();
            let mut buf = [0u8; 2];
            stream.read(&mut buf).ok();
            count += 1;
        }
    }
    
    let elapsed = start.elapsed().as_secs_f64();
    count as f64 / elapsed
}

// QPACK Encoder
fn qpack_encode(headers: &[(String, String)]) -> Vec<u8> {
    let mut buf = Vec::new();
    // Required Insert Count = 0, Delta Base = 0
    buf.push(0); // RIC
    buf.push(0); // Delta
    
    for (name, value) in headers {
        if let Some(idx) = find_static_idx(name, value) {
            // Indexed Field Line
            buf.push(0xC0 | (idx as u8 & 0x3F));
        } else if let Some(idx) = STATIC_TABLE.iter().position(|e| e.0 == *name) {
            // Literal with name reference
            buf.push(0x40 | (idx as u8 & 0x0F));
            buf.push((value.len() as u8) | 0x80); // H=1, len
            buf.extend_from_slice(value.as_bytes());
        } else {
            // Literal with literal name
            buf.push(0x20 | (name.len() as u8 & 0x07));
            buf.extend_from_slice(name.as_bytes());
            buf.push(0x80 | (value.len() as u8)); // H=1, len
            buf.extend_from_slice(value.as_bytes());
        }
    }
    buf
}

// QPACK Benchmark
fn qpack_bench(iters: usize) -> f64 {
    let headers = vec![
        (":method".to_string(), "GET".to_string()),
        (":scheme".to_string(), "https".to_string()),
        (":path".to_string(), "/".to_string()),
        (":authority".to_string(), "localhost".to_string()),
        ("accept".to_string(), "*/*".to_string()),
        ("content-type".to_string(), "application/json".to_string()),
        ("user-agent".to_string(), "rust".to_string()),
    ];
    
    let start = Instant::now();
    for _ in 0..iters {
        let _ = qpack_encode(&headers);
    }
    let elapsed = start.elapsed().as_secs_f64();
    iters as f64 / elapsed
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let mode = args.get(1).map(|s| s.as_str()).unwrap_or("qpack");
    let count: usize = args.get(2).and_then(|s| s.parse().ok()).unwrap_or(50000);
    
    match mode {
        "qpack" => {
            let ips = qpack_bench(count);
            println!("ips={}", ips);
        }
        "h1" => {
            let rps = h1_benchmark(4999, count);
            println!("rps={}", rps);
        }
        "all" => {
            let qpack_ips = qpack_bench(count);
            println!("qpack_ips={}", qpack_ips);
            
            let h1_rps = h1_benchmark(4999, count.min(5000));
            println!("h1_rps={}", h1_rps);
        }
        _ => {
            eprintln!("Usage: {} [qpack|h1|all] [iters]", args[0]);
        }
    }
}
