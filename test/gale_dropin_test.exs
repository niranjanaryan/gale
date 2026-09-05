defmodule GaleDropinTest do
  use ExUnit.Case, async: false

  test "Gale.start_link is a Bandit drop-in and injects alt-svc" do
    port = 4911
    {:ok, pid} = Gale.start_link(plug: Gale.BenchPlug, port: port, scheme: :http)
    {:ok, resp} = Gale.get("http://127.0.0.1:#{port}/")
    assert resp.status == 200
    assert resp.body == "ok"
    alts = Req.Response.get_header(resp, "alt-svc")
    assert Enum.any?(List.wrap(alts), &String.contains?(&1, "h3="))
    Process.exit(pid, :normal)
  end

  test "Gale.PhoenixAdapter.child_specs matches Bandit shape" do
    specs =
      Gale.PhoenixAdapter.child_specs(Gale.BenchPlug,
        otp_app: :gale,
        http: [port: 0]
      )

    assert [%{id: {Gale.BenchPlug, :http}}] = specs
    assert {Gale.Server, :start_link, [_opts]} = hd(specs).start
  end

  test "Gale.PhoenixAdapter merges http3: true with https certs" do
    [spec] =
      Gale.PhoenixAdapter.child_specs(Gale.BenchPlug,
        otp_app: :gale,
        https: [port: 4443, certfile: "cert.pem", keyfile: "key.pem"],
        http3: true
      )

    assert spec.id == {Gale.BenchPlug, :https}
    {_m, _f, [opts]} = spec.start
    assert Keyword.get(opts, :http3)[:port] == 4443
    assert Keyword.get(opts, :http3)[:certfile] == "cert.pem"
  end

  test "Gale.Finch start_link and request (H1)" do
    {:ok, _} = Gale.Finch.start_link(name: Gale.FinchTest)
    req = Gale.Finch.build(:get, "http://example.com")
    assert %Finch.Request{method: "GET"} = req
  end

  test "Gale.Req.get is a Req drop-in" do
    assert {:ok, %Req.Response{}} =
             Gale.Req.get("http://example.com", retry: false, redirect: false)
  rescue
    # network optional
    e in [Mint.TransportError, Req.TransportError] -> assert e
  end

  test "codec NIF still works through Gale facade" do
    assert Gale.nif_loaded?()
    assert {:ok, bin} = Gale.qpack_encode([{":method", "GET"}])
    assert {:ok, _} = Gale.qpack_decode(bin)
  end
end
