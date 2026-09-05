defmodule Gale.Elixir do
  @moduledoc """
  Pure-Elixir QPACK static encoder (same rules as the Zig NIF) for benches.
  """

  @static [
    {":authority", ""},
    {":path", "/"},
    {"age", "0"},
    {"content-disposition", ""},
    {"content-length", "0"},
    {"cookie", ""},
    {"date", ""},
    {"etag", ""},
    {"if-modified-since", ""},
    {"if-none-match", ""},
    {"last-modified", ""},
    {"link", ""},
    {"location", ""},
    {"referer", ""},
    {"set-cookie", ""},
    {":method", "CONNECT"},
    {":method", "DELETE"},
    {":method", "GET"},
    {":method", "HEAD"},
    {":method", "OPTIONS"},
    {":method", "POST"},
    {":method", "PUT"},
    {":scheme", "http"},
    {":scheme", "https"},
    {":status", "103"},
    {":status", "200"},
    {":status", "304"},
    {":status", "404"},
    {":status", "503"},
    {"accept", "*/*"},
    {"accept", "application/dns-message"},
    {"accept-encoding", "gzip, deflate, br"},
    {"accept-ranges", "bytes"},
    {"access-control-allow-headers", "cache-control"},
    {"access-control-allow-headers", "content-type"},
    {"access-control-allow-origin", "*"},
    {"cache-control", "max-age=0"},
    {"cache-control", "max-age=2592000"},
    {"cache-control", "max-age=604800"},
    {"cache-control", "no-cache"},
    {"cache-control", "no-store"},
    {"cache-control", "public, max-age=31536000"},
    {"content-encoding", "br"},
    {"content-encoding", "gzip"},
    {"content-type", "application/dns-message"},
    {"content-type", "application/javascript"},
    {"content-type", "application/json"},
    {"content-type", "application/x-www-form-urlencoded"},
    {"content-type", "image/gif"},
    {"content-type", "image/jpeg"},
    {"content-type", "image/png"},
    {"content-type", "text/css"},
    {"content-type", "text/html; charset=utf-8"},
    {"content-type", "text/plain"},
    {"content-type", "text/plain;charset=utf-8"},
    {"range", "bytes=0-"},
    {"strict-transport-security", "max-age=31536000"},
    {"strict-transport-security", "max-age=31536000; includesubdomains"},
    {"strict-transport-security", "max-age=31536000; includesubdomains; preload"},
    {"x-content-type-options", "nosniff"},
    {"x-xss-protection", "1; mode=block"},
    {":status", "100"},
    {":status", "204"},
    {":status", "206"},
    {":status", "302"},
    {":status", "400"},
    {":status", "403"},
    {":status", "421"},
    {":status", "425"},
    {":status", "500"},
    {"accept-language", ""},
    {"access-control-allow-credentials", "FALSE"},
    {"access-control-allow-credentials", "TRUE"},
    {"access-control-allow-headers", "*"},
    {"access-control-allow-methods", "get"},
    {"access-control-allow-methods", "get, post, options"},
    {"access-control-allow-methods", "options"},
    {"access-control-expose-headers", "content-length"},
    {"access-control-request-headers", "content-type"},
    {"access-control-request-method", "get"},
    {"access-control-request-method", "post"},
    {"alt-svc", "clear"},
    {"authorization", ""},
    {"content-security-policy", "script-src 'none'; object-src 'none'; base-uri 'none'"},
    {"early-data", "1"},
    {"expect-ct", ""},
    {"forwarded", ""},
    {"if-range", ""},
    {"origin", ""},
    {"purpose", "prefetch"},
    {"server", ""},
    {"timing-allow-origin", "*"},
    {"upgrade-insecure-requests", "1"},
    {"user-agent", ""},
    {"x-forwarded-for", ""},
    {"x-frame-options", "deny"},
    {"x-frame-options", "sameorigin"}
  ]

  def qpack_encode(headers) do
    iodata = [0, 0 | Enum.map(headers, &encode_header/1)]
    {:ok, IO.iodata_to_binary(iodata)}
  end

  defp encode_header({name, value}) do
    case static_both(name, value) do
      idx when is_integer(idx) ->
        encode_int(idx, 6, 0xC0)

      nil ->
        case static_name(name) do
          idx when is_integer(idx) ->
            [encode_int(idx, 4, 0x50), encode_string(value)]

          nil ->
            [encode_int(byte_size(name), 3, 0x20), name, encode_string(value)]
        end
    end
  end

  defp static_both(name, value) do
    Enum.find_index(@static, fn {n, v} -> n == name and v == value end)
  end

  defp static_name(name) do
    Enum.find_index(@static, fn {n, _} -> n == name end)
  end

  defp encode_int(n, prefix_bits, first_mask) do
    max = Bitwise.bsl(1, prefix_bits) - 1

    if n < max do
      <<Bitwise.bor(first_mask, n)>>
    else
      rest = n - max
      [<<Bitwise.bor(first_mask, max)>> | encode_rest(rest)]
    end
  end

  defp encode_rest(rest) when rest < 128, do: [<<rest>>]

  defp encode_rest(rest) do
    [<<Bitwise.bor(rem(rest, 128), 128)>> | encode_rest(div(rest, 128))]
  end

  defp encode_string(s) do
    [encode_int(byte_size(s), 7, 0), s]
  end

  def quic_varint_encode(n) when n <= 63, do: {:ok, <<n>>}
  def quic_varint_encode(n) when n <= 16383, do: {:ok, <<0x40::2, n::14>>}
  def quic_varint_encode(n) when n <= 1_073_741_823, do: {:ok, <<0x80::2, n::30>>}
  def quic_varint_encode(n), do: {:ok, <<0xC0::2, n::62>>}
end
