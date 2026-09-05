//! HTTP/3 + QPACK (static table) + QUIC varint / long-header parse.
//! Zig NIF for Elixir. No sockets here — UDP lives in the BEAM.

const std = @import("std");
const erl_nif = @cImport({
    @cInclude("erl_nif.h");
});

const alloc = std.heap.c_allocator;

// RFC 9204 Appendix A — static table (name, value). Empty value = name-only.
const StaticEntry = struct { name: []const u8, value: []const u8 };

const STATIC = [_]StaticEntry{
    .{ .name = ":authority", .value = "" },
    .{ .name = ":path", .value = "/" },
    .{ .name = "age", .value = "0" },
    .{ .name = "content-disposition", .value = "" },
    .{ .name = "content-length", .value = "0" },
    .{ .name = "cookie", .value = "" },
    .{ .name = "date", .value = "" },
    .{ .name = "etag", .value = "" },
    .{ .name = "if-modified-since", .value = "" },
    .{ .name = "if-none-match", .value = "" },
    .{ .name = "last-modified", .value = "" },
    .{ .name = "link", .value = "" },
    .{ .name = "location", .value = "" },
    .{ .name = "referer", .value = "" },
    .{ .name = "set-cookie", .value = "" },
    .{ .name = ":method", .value = "CONNECT" },
    .{ .name = ":method", .value = "DELETE" },
    .{ .name = ":method", .value = "GET" },
    .{ .name = ":method", .value = "HEAD" },
    .{ .name = ":method", .value = "OPTIONS" },
    .{ .name = ":method", .value = "POST" },
    .{ .name = ":method", .value = "PUT" },
    .{ .name = ":scheme", .value = "http" },
    .{ .name = ":scheme", .value = "https" },
    .{ .name = ":status", .value = "103" },
    .{ .name = ":status", .value = "200" },
    .{ .name = ":status", .value = "304" },
    .{ .name = ":status", .value = "404" },
    .{ .name = ":status", .value = "503" },
    .{ .name = "accept", .value = "*/*" },
    .{ .name = "accept", .value = "application/dns-message" },
    .{ .name = "accept-encoding", .value = "gzip, deflate, br" },
    .{ .name = "accept-ranges", .value = "bytes" },
    .{ .name = "access-control-allow-headers", .value = "cache-control" },
    .{ .name = "access-control-allow-headers", .value = "content-type" },
    .{ .name = "access-control-allow-origin", .value = "*" },
    .{ .name = "cache-control", .value = "max-age=0" },
    .{ .name = "cache-control", .value = "max-age=2592000" },
    .{ .name = "cache-control", .value = "max-age=604800" },
    .{ .name = "cache-control", .value = "no-cache" },
    .{ .name = "cache-control", .value = "no-store" },
    .{ .name = "cache-control", .value = "public, max-age=31536000" },
    .{ .name = "content-encoding", .value = "br" },
    .{ .name = "content-encoding", .value = "gzip" },
    .{ .name = "content-type", .value = "application/dns-message" },
    .{ .name = "content-type", .value = "application/javascript" },
    .{ .name = "content-type", .value = "application/json" },
    .{ .name = "content-type", .value = "application/x-www-form-urlencoded" },
    .{ .name = "content-type", .value = "image/gif" },
    .{ .name = "content-type", .value = "image/jpeg" },
    .{ .name = "content-type", .value = "image/png" },
    .{ .name = "content-type", .value = "text/css" },
    .{ .name = "content-type", .value = "text/html; charset=utf-8" },
    .{ .name = "content-type", .value = "text/plain" },
    .{ .name = "content-type", .value = "text/plain;charset=utf-8" },
    .{ .name = "range", .value = "bytes=0-" },
    .{ .name = "strict-transport-security", .value = "max-age=31536000" },
    .{ .name = "strict-transport-security", .value = "max-age=31536000; includesubdomains" },
    .{ .name = "strict-transport-security", .value = "max-age=31536000; includesubdomains; preload" },
    .{ .name = "x-content-type-options", .value = "nosniff" },
    .{ .name = "x-xss-protection", .value = "1; mode=block" },
    .{ .name = ":status", .value = "100" },
    .{ .name = ":status", .value = "204" },
    .{ .name = ":status", .value = "206" },
    .{ .name = ":status", .value = "302" },
    .{ .name = ":status", .value = "400" },
    .{ .name = ":status", .value = "403" },
    .{ .name = ":status", .value = "421" },
    .{ .name = ":status", .value = "425" },
    .{ .name = ":status", .value = "500" },
    .{ .name = "accept-language", .value = "" },
    .{ .name = "access-control-allow-credentials", .value = "FALSE" },
    .{ .name = "access-control-allow-credentials", .value = "TRUE" },
    .{ .name = "access-control-allow-headers", .value = "*" },
    .{ .name = "access-control-allow-methods", .value = "get" },
    .{ .name = "access-control-allow-methods", .value = "get, post, options" },
    .{ .name = "access-control-allow-methods", .value = "options" },
    .{ .name = "access-control-expose-headers", .value = "content-length" },
    .{ .name = "access-control-request-headers", .value = "content-type" },
    .{ .name = "access-control-request-method", .value = "get" },
    .{ .name = "access-control-request-method", .value = "post" },
    .{ .name = "alt-svc", .value = "clear" },
    .{ .name = "authorization", .value = "" },
    .{ .name = "content-security-policy", .value = "script-src 'none'; object-src 'none'; base-uri 'none'" },
    .{ .name = "early-data", .value = "1" },
    .{ .name = "expect-ct", .value = "" },
    .{ .name = "forwarded", .value = "" },
    .{ .name = "if-range", .value = "" },
    .{ .name = "origin", .value = "" },
    .{ .name = "purpose", .value = "prefetch" },
    .{ .name = "server", .value = "" },
    .{ .name = "timing-allow-origin", .value = "*" },
    .{ .name = "upgrade-insecure-requests", .value = "1" },
    .{ .name = "user-agent", .value = "" },
    .{ .name = "x-forwarded-for", .value = "" },
    .{ .name = "x-frame-options", .value = "deny" },
    .{ .name = "x-frame-options", .value = "sameorigin" },
};

fn find_static_both(name: []const u8, value: []const u8) ?usize {
    for (STATIC, 0..) |e, i| {
        if (std.mem.eql(u8, e.name, name) and std.mem.eql(u8, e.value, value)) return i;
    }
    return null;
}

fn find_static_name(name: []const u8) ?usize {
    for (STATIC, 0..) |e, i| {
        if (std.mem.eql(u8, e.name, name)) return i;
    }
    return null;
}

fn encode_int(buf: *std.ArrayList(u8), n: usize, prefix_bits: u4, first_mask: u8) !void {
    const max: usize = (@as(usize, 1) << prefix_bits) - 1;
    if (n < max) {
        try buf.append(alloc, first_mask | @as(u8, @intCast(n)));
        return;
    }
    try buf.append(alloc, first_mask | @as(u8, @intCast(max)));
    var rest = n - max;
    while (rest >= 128) {
        try buf.append(alloc, @as(u8, @intCast((rest % 128) | 128)));
        rest /= 128;
    }
    try buf.append(alloc, @as(u8, @intCast(rest)));
}

fn encode_string_lit(buf: *std.ArrayList(u8), s: []const u8) !void {
    // H=0 (not Huffman), 7-bit prefix length
    try encode_int(buf, s.len, 7, 0);
    try buf.appendSlice(alloc, s);
}

fn qpack_encode(headers: []const [2][]const u8) ![]u8 {
    var buf = std.ArrayList(u8).empty;
    errdefer buf.deinit(alloc);
    // Required Insert Count = 0, Base = 0 (static-only encoder)
    try buf.append(alloc, 0);
    try buf.append(alloc, 0);

    for (headers) |hv| {
        const name = hv[0];
        const value = hv[1];
        if (find_static_both(name, value)) |idx| {
            // Indexed Field Line, T=1 (static), 6-bit prefix, high bit 1
            try encode_int(&buf, idx, 6, 0xC0);
            continue;
        }
        if (find_static_name(name)) |idx| {
            // Literal Field Line With Name Reference, N=0 T=1, 4-bit prefix, pattern 01 0 1
            try encode_int(&buf, idx, 4, 0x50);
            try encode_string_lit(&buf, value);
            continue;
        }
        // Literal Field Line With Literal Name, N=0, 3-bit prefix, pattern 001 0
        try encode_int(&buf, name.len, 3, 0x20);
        try buf.appendSlice(alloc, name);
        try encode_string_lit(&buf, value);
    }
    return buf.toOwnedSlice(alloc);
}

const DecodeError = error{ Truncated, BadIndex };

fn decode_int(data: []const u8, i: *usize, prefix_bits: u4) DecodeError!usize {
    if (i.* >= data.len) return error.Truncated;
    const max: usize = (@as(usize, 1) << prefix_bits) - 1;
    const mask: u8 = @intCast(max);
    var n: usize = data[i.*] & mask;
    i.* += 1;
    if (n < max) return n;
    var m: usize = 0;
    while (true) {
        if (i.* >= data.len) return error.Truncated;
        const b = data[i.*];
        i.* += 1;
        n += @as(usize, b & 0x7f) << @intCast(m);
        m += 7;
        if (b & 0x80 == 0) break;
    }
    return n;
}

fn decode_string(data: []const u8, i: *usize) DecodeError![]const u8 {
    if (i.* >= data.len) return error.Truncated;
    const huffman = data[i.*] & 0x80 != 0;
    const len = try decode_int(data, i, 7);
    if (i.* + len > data.len) return error.Truncated;
    const s = data[i.* .. i.* + len];
    i.* += len;
    if (huffman) return error.BadIndex; // static-only decoder: no Huffman
    return s;
}

const HeaderPair = struct { name: []const u8, value: []const u8 };

fn qpack_decode(data: []const u8) ![]HeaderPair {
    var i: usize = 0;
    // skip Required Insert Count + Delta Base (we require 0/0 for static-only)
    if (data.len < 2) return error.Truncated;
    _ = try decode_int(data, &i, 8);
    _ = try decode_int(data, &i, 7);

    var out = std.ArrayList(HeaderPair).empty;
    errdefer out.deinit(alloc);

    while (i < data.len) {
        const b = data[i];
        if (b & 0x80 != 0) {
            // Indexed Field Line
            const t_static = b & 0x40 != 0;
            const idx = try decode_int(data, &i, 6);
            if (!t_static or idx >= STATIC.len) return error.BadIndex;
            try out.append(alloc, .{ .name = STATIC[idx].name, .value = STATIC[idx].value });
        } else if (b & 0x40 != 0) {
            // Literal with name ref
            const t_static = b & 0x10 != 0;
            const idx = try decode_int(data, &i, 4);
            if (!t_static or idx >= STATIC.len) return error.BadIndex;
            const val = try decode_string(data, &i);
            try out.append(alloc, .{ .name = STATIC[idx].name, .value = val });
        } else if (b & 0x20 != 0) {
            // Literal with literal name (N bit at 0x10)
            const nlen = try decode_int(data, &i, 3);
            if (i + nlen > data.len) return error.Truncated;
            const name = data[i .. i + nlen];
            i += nlen;
            const val = try decode_string(data, &i);
            try out.append(alloc, .{ .name = name, .value = val });
        } else {
            return error.BadIndex;
        }
    }
    return out.toOwnedSlice(alloc);
}

fn write_varint(buf: *std.ArrayList(u8), n: u64) !void {
    if (n <= 63) {
        try buf.append(alloc, @intCast(n));
    } else if (n <= 16383) {
        try buf.append(alloc, @intCast(0x40 | (n >> 8)));
        try buf.append(alloc, @intCast(n & 0xff));
    } else if (n <= 1073741823) {
        try buf.append(alloc, @intCast(0x80 | (n >> 24)));
        try buf.append(alloc, @intCast((n >> 16) & 0xff));
        try buf.append(alloc, @intCast((n >> 8) & 0xff));
        try buf.append(alloc, @intCast(n & 0xff));
    } else {
        try buf.append(alloc, @intCast(0xc0 | (n >> 56)));
        var shift: u6 = 48;
        while (true) {
            try buf.append(alloc, @intCast((n >> shift) & 0xff));
            if (shift == 0) break;
            shift -= 8;
        }
    }
}

fn read_varint(data: []const u8, i: *usize) DecodeError!u64 {
    if (i.* >= data.len) return error.Truncated;
    const b0 = data[i.*];
    const tag = b0 >> 6;
    const len: usize = @as(usize, 1) << @intCast(tag);
    if (i.* + len > data.len) return error.Truncated;
    var n: u64 = b0 & 0x3f;
    var k: usize = 1;
    while (k < len) : (k += 1) {
        n = (n << 8) | data[i.* + k];
    }
    i.* += len;
    return n;
}

fn h3_frame_encode(kind: u64, payload: []const u8) ![]u8 {
    var buf = std.ArrayList(u8).empty;
    errdefer buf.deinit(alloc);
    try write_varint(&buf, kind);
    try write_varint(&buf, payload.len);
    try buf.appendSlice(alloc, payload);
    return buf.toOwnedSlice(alloc);
}

const Frame = struct { kind: u64, payload: []const u8 };

fn h3_frame_decode(data: []const u8) !Frame {
    var i: usize = 0;
    const kind = try read_varint(data, &i);
    const len = try read_varint(data, &i);
    if (i + len > data.len) return error.Truncated;
    return .{ .kind = kind, .payload = data[i .. i + @as(usize, @intCast(len))] };
}

/// Parse a QUIC long header (RFC 9000 §17.2). Returns a 4-tuple via NIF.
const LongHeader = struct {
    form: u8,
    fixed: u8,
    packet_type: u8,
    version: u32,
    dcid: []const u8,
    scid: []const u8,
};

fn parse_long_header(data: []const u8) DecodeError!LongHeader {
    if (data.len < 6) return error.Truncated;
    const first = data[0];
    if (first & 0x80 == 0) return error.BadIndex; // short header
    const version: u32 = @as(u32, data[1]) << 24 | @as(u32, data[2]) << 16 | @as(u32, data[3]) << 8 | data[4];
    var i: usize = 5;
    const dcid_len = data[i];
    i += 1;
    if (i + dcid_len > data.len) return error.Truncated;
    const dcid = data[i .. i + dcid_len];
    i += dcid_len;
    if (i >= data.len) return error.Truncated;
    const scid_len = data[i];
    i += 1;
    if (i + scid_len > data.len) return error.Truncated;
    const scid = data[i .. i + scid_len];
    return .{
        .form = 1,
        .fixed = (first >> 6) & 1,
        .packet_type = (first >> 4) & 0x3,
        .version = version,
        .dcid = dcid,
        .scid = scid,
    };
}

// --- NIF glue ---

fn ok_bin(env: *erl_nif.ErlNifEnv, bytes: []const u8) erl_nif.ERL_NIF_TERM {
    var bin: erl_nif.ErlNifBinary = undefined;
    if (erl_nif.enif_alloc_binary(bytes.len, &bin) == 0) {
        return erl_nif.enif_make_atom(env, "enomem");
    }
    @memcpy(bin.data[0..bytes.len], bytes);
    const term = erl_nif.enif_make_binary(env, &bin);
    return erl_nif.enif_make_tuple2(env, erl_nif.enif_make_atom(env, "ok"), term);
}

fn err_atom(env: *erl_nif.ErlNifEnv, name: [*c]const u8) erl_nif.ERL_NIF_TERM {
    return erl_nif.enif_make_tuple2(
        env,
        erl_nif.enif_make_atom(env, "error"),
        erl_nif.enif_make_atom(env, name),
    );
}

fn inspect_bin(env: *erl_nif.ErlNifEnv, term: erl_nif.ERL_NIF_TERM) ?[]const u8 {
    var bin: erl_nif.ErlNifBinary = undefined;
    if (erl_nif.enif_inspect_binary(env, term, &bin) == 0) return null;
    const p: [*]const u8 = @ptrCast(bin.data);
    return p[0..bin.size];
}

fn list_headers(env: *erl_nif.ErlNifEnv, list: erl_nif.ERL_NIF_TERM, out: *std.ArrayList([2][]const u8)) bool {
    var cell = list;
    var head: erl_nif.ERL_NIF_TERM = undefined;
    var tail: erl_nif.ERL_NIF_TERM = undefined;
    while (erl_nif.enif_get_list_cell(env, cell, &head, &tail) != 0) {
        var arity: c_int = 0;
        var tuple: [*c]const erl_nif.ERL_NIF_TERM = undefined;
        if (erl_nif.enif_get_tuple(env, head, &arity, &tuple) == 0 or arity != 2) return false;
        const n = inspect_bin(env, tuple[0]) orelse return false;
        const v = inspect_bin(env, tuple[1]) orelse return false;
        out.append(alloc, .{ n, v }) catch return false;
        cell = tail;
    }
    return erl_nif.enif_is_empty_list(env, cell) != 0;
}

export fn nif_qpack_encode(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    var hdrs = std.ArrayList([2][]const u8).empty;
    defer hdrs.deinit(alloc);
    if (!list_headers(env, argv[0], &hdrs)) return err_atom(env, "badarg");
    const bytes = qpack_encode(hdrs.items) catch return err_atom(env, "encode");
    defer alloc.free(bytes);
    return ok_bin(env, bytes);
}

export fn nif_qpack_decode(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    const data = inspect_bin(env, argv[0]) orelse return err_atom(env, "badarg");
    const hdrs = qpack_decode(data) catch return err_atom(env, "decode");
    defer alloc.free(hdrs);
    var acc = erl_nif.enif_make_list(env, 0);
    var idx: usize = hdrs.len;
    while (idx > 0) {
        idx -= 1;
        const name = ok_bin_raw(env, hdrs[idx].name);
        const value = ok_bin_raw(env, hdrs[idx].value);
        const pair = erl_nif.enif_make_tuple2(env, name, value);
        acc = erl_nif.enif_make_list_cell(env, pair, acc);
    }
    return erl_nif.enif_make_tuple2(env, erl_nif.enif_make_atom(env, "ok"), acc);
}

fn ok_bin_raw(env: *erl_nif.ErlNifEnv, bytes: []const u8) erl_nif.ERL_NIF_TERM {
    var bin: erl_nif.ErlNifBinary = undefined;
    if (erl_nif.enif_alloc_binary(bytes.len, &bin) == 0) {
        return erl_nif.enif_make_atom(env, "enomem");
    }
    @memcpy(bin.data[0..bytes.len], bytes);
    return erl_nif.enif_make_binary(env, &bin);
}

export fn nif_h3_frame_encode(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    var kind: c_ulong = 0;
    if (erl_nif.enif_get_ulong(env, argv[0], &kind) == 0) return err_atom(env, "badarg");
    const payload = inspect_bin(env, argv[1]) orelse return err_atom(env, "badarg");
    const bytes = h3_frame_encode(kind, payload) catch return err_atom(env, "encode");
    defer alloc.free(bytes);
    return ok_bin(env, bytes);
}

export fn nif_h3_frame_decode(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    const data = inspect_bin(env, argv[0]) orelse return err_atom(env, "badarg");
    const f = h3_frame_decode(data) catch return err_atom(env, "decode");
    const kind = erl_nif.enif_make_ulong(env, @intCast(f.kind));
    const payload = ok_bin_raw(env, f.payload);
    const tup = erl_nif.enif_make_tuple2(env, kind, payload);
    return erl_nif.enif_make_tuple2(env, erl_nif.enif_make_atom(env, "ok"), tup);
}

export fn nif_quic_varint_encode(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    var n: c_ulong = 0;
    if (erl_nif.enif_get_ulong(env, argv[0], &n) == 0) return err_atom(env, "badarg");
    var buf = std.ArrayList(u8).empty;
    defer buf.deinit(alloc);
    write_varint(&buf, n) catch return err_atom(env, "encode");
    return ok_bin(env, buf.items);
}

export fn nif_quic_varint_decode(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    const data = inspect_bin(env, argv[0]) orelse return err_atom(env, "badarg");
    var i: usize = 0;
    const n = read_varint(data, &i) catch return err_atom(env, "decode");
    const num = erl_nif.enif_make_ulong(env, @intCast(n));
    const rest = ok_bin_raw(env, data[i..]);
    const tup = erl_nif.enif_make_tuple2(env, num, rest);
    return erl_nif.enif_make_tuple2(env, erl_nif.enif_make_atom(env, "ok"), tup);
}

export fn nif_quic_parse_long_header(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    const data = inspect_bin(env, argv[0]) orelse return err_atom(env, "badarg");
    const h = parse_long_header(data) catch return err_atom(env, "decode");
    var keys = [_]erl_nif.ERL_NIF_TERM{
        erl_nif.enif_make_atom(env, "packet_type"),
        erl_nif.enif_make_atom(env, "version"),
        erl_nif.enif_make_atom(env, "dcid"),
        erl_nif.enif_make_atom(env, "scid"),
    };
    var vals = [_]erl_nif.ERL_NIF_TERM{
        erl_nif.enif_make_uint(env, h.packet_type),
        erl_nif.enif_make_uint(env, h.version),
        ok_bin_raw(env, h.dcid),
        ok_bin_raw(env, h.scid),
    };
    var map: erl_nif.ERL_NIF_TERM = undefined;
    _ = erl_nif.enif_make_map_from_arrays(env, &keys, &vals, 4, &map);
    return erl_nif.enif_make_tuple2(env, erl_nif.enif_make_atom(env, "ok"), map);
}

export fn nif_blake3(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    const data = inspect_bin(env, argv[0]) orelse return err_atom(env, "badarg");
    var out: [32]u8 = undefined;
    std.crypto.hash.Blake3.hash(data, &out, .{});
    return ok_bin_raw(env, &out);
}

export fn nif_xxh3(env: *erl_nif.ErlNifEnv, argc: c_int, argv: [*]const erl_nif.ERL_NIF_TERM) callconv(.c) erl_nif.ERL_NIF_TERM {
    _ = argc;
    const data = inspect_bin(env, argv[0]) orelse return err_atom(env, "badarg");
    const h = std.hash.XxHash3.hash(0, data);
    return erl_nif.enif_make_uint64(env, h);
}

var nif_funcs = [_]erl_nif.ErlNifFunc{
    .{ .name = @as([*]const u8, @ptrCast("qpack_encode")), .arity = 1, .fptr = @ptrCast(&nif_qpack_encode), .flags = 0 },
    .{ .name = @as([*]const u8, @ptrCast("qpack_decode")), .arity = 1, .fptr = @ptrCast(&nif_qpack_decode), .flags = 0 },
    .{ .name = @as([*]const u8, @ptrCast("h3_frame_encode")), .arity = 2, .fptr = @ptrCast(&nif_h3_frame_encode), .flags = 0 },
    .{ .name = @as([*]const u8, @ptrCast("h3_frame_decode")), .arity = 1, .fptr = @ptrCast(&nif_h3_frame_decode), .flags = 0 },
    .{ .name = @as([*]const u8, @ptrCast("quic_varint_encode")), .arity = 1, .fptr = @ptrCast(&nif_quic_varint_encode), .flags = 0 },
    .{ .name = @as([*]const u8, @ptrCast("quic_varint_decode")), .arity = 1, .fptr = @ptrCast(&nif_quic_varint_decode), .flags = 0 },
    .{ .name = @as([*]const u8, @ptrCast("quic_parse_long_header")), .arity = 1, .fptr = @ptrCast(&nif_quic_parse_long_header), .flags = 0 },
    .{ .name = @as([*]const u8, @ptrCast("blake3")), .arity = 1, .fptr = @ptrCast(&nif_blake3), .flags = 0 },
    .{ .name = @as([*]const u8, @ptrCast("xxh3")), .arity = 1, .fptr = @ptrCast(&nif_xxh3), .flags = 0 },
};

var nif_entry = erl_nif.ErlNifEntry{
    .major = erl_nif.ERL_NIF_MAJOR_VERSION,
    .minor = erl_nif.ERL_NIF_MINOR_VERSION,
    .name = @as([*]const u8, @ptrCast("Elixir.Gale.Native")),
    .num_of_funcs = nif_funcs.len,
    .funcs = @as([*]erl_nif.ErlNifFunc, &nif_funcs),
    .load = null,
    .reload = null,
    .upgrade = null,
    .unload = null,
    .vm_variant = @as([*]const u8, @ptrCast(erl_nif.ERL_NIF_VM_VARIANT)),
    .options = 1,
    .sizeof_ErlNifResourceTypeInit = @sizeOf(erl_nif.ErlNifResourceTypeInit),
    .min_erts = null,
};

export fn nif_init() callconv(.c) [*c]erl_nif.ErlNifEntry {
    return &nif_entry;
}
