defmodule GaleTest do
  use ExUnit.Case, async: true

  @headers [
    {":method", "GET"},
    {":scheme", "https"},
    {":path", "/"},
    {":authority", "localhost"},
    {"accept", "*/*"},
    {"content-type", "application/json"},
    {"x-custom", "v"}
  ]

  test "Zig NIF loads" do
    assert Gale.nif_loaded?()
  end

  test "QPACK round-trip via Zig NIF" do
    assert {:ok, bin} = Gale.qpack_encode(@headers)
    assert is_binary(bin) and byte_size(bin) > 2
    assert {:ok, decoded} = Gale.qpack_decode(bin)
    names = Enum.map(decoded, fn {n, _} -> n end)
    assert ":method" in names
    assert "x-custom" in names
  end

  test "Elixir QPACK encoder agrees with Zig on indexed GET" do
    hdrs = [{":method", "GET"}, {":scheme", "https"}, {":path", "/"}]
    assert {:ok, zig} = Gale.qpack_encode(hdrs)
    assert {:ok, elx} = Gale.Elixir.qpack_encode(hdrs)
    assert zig == elx
  end

  test "HTTP/3 DATA frame encode/decode" do
    assert {:ok, bin} = Gale.h3_frame_encode(0, "hello")
    assert {:ok, {0, "hello"}} = Gale.h3_frame_decode(bin)
  end

  test "QUIC varint 1/2/4/8 byte forms" do
    for n <- [0, 63, 64, 16383, 16384, 1_073_741_823, 1_073_741_824] do
      assert {:ok, bin} = Gale.quic_varint_encode(n)
      assert {:ok, {^n, <<>>}} = Gale.quic_varint_decode(bin)
    end
  end

  test "QUIC long header parse (Initial, v1)" do
    # header form=1, fixed=1, type=0 (Initial), reserved=0, pnlen=0 → 0xC0
    dcid = <<1, 2, 3, 4>>
    scid = <<9, 9>>
    pkt = <<0xC0, 0, 0, 0, 1, 4, dcid::binary, 2, scid::binary, 0, 0, 0>>
    assert {:ok, map} = Gale.quic_parse_long_header(pkt)
    assert map.packet_type == 0
    assert map.version == 1
    assert map.dcid == dcid
    assert map.scid == scid
  end

  test "short header is rejected" do
    assert {:error, :decode} = Gale.quic_parse_long_header(<<0x40, 1, 2, 3>>)
  end

  test "Alt-Svc helper" do
    assert Gale.Plug.Adapter.alt_svc("ex.com", 443) == ~s(h3="ex.com:443"; ma=86400)
  end

  test "ecosystem survey includes gale and bandit" do
    ids = Gale.Survey.probe() |> Enum.filter(& &1.loaded) |> Enum.map(& &1.id)
    assert :gale in ids
    assert :bandit in ids
  end
end
