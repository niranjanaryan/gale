defmodule Mix.Tasks.Gale.Bench do
  @moduledoc false
  use Mix.Task

  @shortdoc "QPACK NIF vs Elixir vs Rust, plus Bandit HTTP/1.1 req/s"

  @headers [
    {":method", "GET"},
    {":scheme", "https"},
    {":path", "/"},
    {":authority", "localhost"},
    {"accept", "*/*"},
    {"content-type", "application/json"},
    {"user-agent", "gale"}
  ]

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("app.start")
    iters = 50_000

    unless Gale.nif_loaded?() do
      Mix.raise("Zig NIF not loaded — run mix compile first")
    end

    {zig_us, _} = :timer.tc(fn -> for _ <- 1..iters, do: Gale.qpack_encode(@headers) end)
    {elx_us, _} = :timer.tc(fn -> for _ <- 1..iters, do: Gale.Elixir.qpack_encode(@headers) end)

    zig_ips = iters * 1_000_000 / zig_us
    elx_ips = iters * 1_000_000 / elx_us

    rust = rust_bench(iters)

    {pkt_us, _} =
      :timer.tc(fn ->
        pkt = <<0xC0, 0, 0, 0, 1, 4, 1, 2, 3, 4, 2, 9, 9, 0>>

        for _ <- 1..iters do
          Gale.quic_parse_long_header(pkt)
        end
      end)

    pkt_ips = iters * 1_000_000 / pkt_us

    hpax = hpax_bench(iters)
    bandit = http_loopback(:bandit, 2_000)
    cowboy = http_loopback(:cowboy, 2_000)
    survey_rows = Gale.Survey.probe()

    lines = [
      "# Gale performance",
      "",
      "Machine: #{:erlang.system_info(:system_architecture)} OTP #{:erlang.system_info(:otp_release)}",
      "Date: #{Date.utc_today()}",
      "",
      "## Ecosystem (loaded in this Mix project)",
      "",
      "| package | loaded | role |",
      "|---|---|---|",
      survey_table(survey_rows),
      "",
      "## QPACK encode (#{iters} iters, 7 headers)",
      "",
      "| backend | iters/s | vs Elixir |",
      "|---|---:|---:|",
      "| Elixir QPACK | #{round(elx_ips)} | 1.00× |",
      "| Gale Zig NIF | #{round(zig_ips)} | #{Float.round(zig_ips / elx_ips, 2)}× |",
      rust_row(rust, elx_ips),
      hpax_row(hpax, elx_ips),
      "",
      "## QUIC long-header parse (Zig NIF)",
      "",
      "#{round(pkt_ips)} packets/s",
      "",
      "## Loopback HTTP/1.1 (Plug `200 ok`, sequential :httpc)",
      "",
      "- Bandit: #{http_line(bandit)}",
      "- Cowboy: #{http_line(cowboy)}",
      "",
      "## Notes",
      "",
      "- Bandit/Cowboy/Mint have no HTTP/3. These numbers are H1 + codec throughput.",
      "- HPAX is HTTP/2 HPACK, included as a header-compression baseline vs QPACK.",
      "- Rust figure is a standalone binary (no NIF call overhead).",
      "- Production H3 for Phoenix: Caddy in front of Bandit; in-VM QUIC via Hex `quic`.",
      ""
    ]

    out = Enum.join(Enum.reject(lines, &is_nil/1), "\n")
    File.mkdir_p!("benchmark")
    File.write!("benchmark/RESULTS.md", out)
    Mix.shell().info(out)
  end

  defp rust_bench(iters) do
    path = System.get_env("PATH", "")
    home = System.get_env("HOME", "")
    System.put_env("PATH", "#{home}/.cargo/bin:#{path}")
    cargo = System.find_executable("cargo")
    if is_nil(cargo), do: :skip, else: do_rust(cargo, iters)
  end

  defp do_rust(cargo, iters) do
    {build_out, build_st} =
      System.cmd(cargo, ["build", "--release"],
        cd: "native/rust",
        stderr_to_stdout: true
      )

    if build_st != 0 do
      Mix.shell().error("rust cargo build failed:\n#{build_out}")
      :skip
    else
      bin = Path.join(["native", "rust", "target", "release", "h3_qpack_bench"])
      {out, st} = System.cmd(Path.expand(bin), [Integer.to_string(iters)], stderr_to_stdout: true)

      if st != 0 do
        Mix.shell().error("rust bench failed:\n#{out}")
        :skip
      else
        case Regex.run(~r/ips=([0-9.]+)/, out) do
          [_, ips] -> {:ok, to_f(ips)}
          _ -> :skip
        end
      end
    end
  end

  defp to_f(ips) do
    if String.contains?(ips, "."), do: String.to_float(ips), else: String.to_integer(ips) * 1.0
  end

  defp rust_row(:skip, _), do: "| Rust CLI | (cargo missing or build failed) | — |"

  defp rust_row({:ok, ips}, elx) do
    "| Rust CLI | #{round(ips)} | #{Float.round(ips / elx, 2)}× |"
  end

  defp survey_table(rows) do
    Enum.map_join(rows, "\n", fn r ->
      "| #{r.id} | #{if r.loaded, do: "yes", else: "no"} | #{r.role} |"
    end)
  end

  defp hpax_bench(iters) do
    if match?({:module, _}, Code.ensure_loaded(HPAX)) do
      {us, _} =
        :timer.tc(fn ->
          for _ <- 1..iters do
            HPAX.encode(:no_store, @headers, HPAX.new(4096))
          end
        end)

      {:ok, iters * 1_000_000 / us}
    else
      :skip
    end
  rescue
    _ -> :skip
  end

  defp hpax_row(:skip, _), do: "| HPAX (HPACK / HTTP/2) | skipped | — |"

  defp hpax_row({:ok, ips}, elx) do
    "| HPAX (HPACK / HTTP/2) | #{round(ips)} | #{Float.round(ips / elx, 2)}× |"
  end

  defp http_loopback(:bandit, n) do
    port = 4891
    {:ok, pid} = Bandit.start_link(plug: Gale.BenchPlug, port: port, scheme: :http)
    rps = httpc_n(port, n)
    Process.exit(pid, :normal)
    {:ok, rps, n}
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp http_loopback(:cowboy, n) do
    port = 4892

    if match?({:module, _}, Code.ensure_loaded(Plug.Cowboy)) do
      {:ok, pid} = Plug.Cowboy.http(Gale.BenchPlug, [], port: port, ref: Gale.CowboyBench)
      rps = httpc_n(port, n)
      Plug.Cowboy.shutdown(Gale.CowboyBench)
      _ = pid
      {:ok, rps, n}
    else
      {:error, "plug_cowboy not loaded"}
    end
  rescue
    e -> {:error, Exception.message(e)}
  end

  defp httpc_n(port, n) do
    :inets.start()
    url = ~c"http://127.0.0.1:#{port}/"
    Process.sleep(50)
    {us, _} = :timer.tc(fn -> for _ <- 1..n, do: :httpc.request(url) end)
    n * 1_000_000 / us
  end

  defp http_line({:ok, rps, n}), do: "#{n} GETs → **#{round(rps)} req/s**"
  defp http_line({:error, m}), do: "skipped (#{m})"
end
