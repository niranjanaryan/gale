defmodule Gale.Bench.Stacks do
  @moduledoc """
  Stacks-specific benchmarks for Gale HTTP/3.

  Benchmarks against Stacks API patterns:
  - `/v2/info` — small JSON, high frequency
  - `/v2/chain_info` — medium JSON, moderate frequency
  - Block explorer HTML — large HTML, low frequency
  - sBTC relay status — small JSON, high frequency

  Run with: `mix bench.stacks`
  """

  @endpoints [
    info: "https://api.stacks.co/v2/info",
    chain_info: "https://api.stacks.co/v2/chain_info",
    block_explorer: "https://explorer.stacks.co/api/v1/blocks?limit=1",
    sbtc_relay: "https://relay.stacks.co/status"
  ]

  @iterations 1000
  @concurrency 7

  def run do
    Mix.Task.run("app.start")

    Mix.shell().info("""
    ╔══════════════════════════════════════════════════════════════════╗
    ║           GALE STACKS BENCHMARK — Stacks API Patterns          ║
    ╚══════════════════════════════════════════════════════════════════╝
    """)

    http3_single_conn()
    http3_parallel_streams()
    http2_baseline()
    http1_baseline()
  end

  defp http3_single_conn do
    Mix.shell().info("\n## HTTP/3 Single Connection (1000 requests)")

    cert = Path.expand("priv/certs/cert.pem")
    key = Path.expand("priv/certs/key.pem")

    if File.exists?(cert) and File.exists?(key) do
      result = bench_endpoint(:info, :http3_single, cert, key, 4943, 1000)
      Mix.shell().info("  /v2/info: #{Kernel.round(result)} req/s")
    else
      Mix.shell().info("  Skipped (certs not found)")
    end
  end

  defp http3_parallel_streams do
    Mix.shell().info("\n## HTTP/3 Parallel Streams (7 streams, 20000 requests)")

    cert = Path.expand("priv/certs/cert.pem")
    key = Path.expand("priv/certs/key.pem")

    if File.exists?(cert) and File.exists?(key) do
      for n <- [3, 5, 7] do
        result = bench_endpoint(:info, :http3_streams, cert, key, 4940 + n, n, 20000)
        Mix.shell().info("  #{n} streams: #{Kernel.round(result)} req/s")
      end
    else
      Mix.shell().info("  Skipped (certs not found)")
    end
  end

  defp http2_baseline do
    Mix.shell().info("\n## HTTP/2 Baseline (1000 requests)")

    {:ok, pid} = Bandit.start_link(plug: Gale.BenchPlug, port: 8443, scheme: :https)
    :timer.sleep(50)

    result = http2_client(8443, 1000)
    Process.exit(pid, :normal)

    Mix.shell().info("  HTTP/2: #{Kernel.round(result)} req/s")
  end

  defp http1_baseline do
    Mix.shell().info("\n## HTTP/1.1 Baseline (1000 requests)")

    {:ok, pid} = Bandit.start_link(plug: Gale.BenchPlug, port: 8080, scheme: :http)
    :timer.sleep(50)

    result = http1_client(8080, 1000)
    Process.exit(pid, :normal)

    Mix.shell().info("  HTTP/1.1: #{Kernel.round(result)} req/s")
  end

  defp bench_endpoint(endpoint, mode, cert, key, port, n_or_streams, total \\ 1000) do
    headers = [
      {":method", "GET"},
      {":scheme", "https"},
      {":path", path_for(endpoint)},
      {":authority", "localhost"}
    ]

    try do
      {:ok, _} = Gale.HTTP3.Listener.start_link(
        {port, Gale.BenchPlug, certfile: cert, keyfile: key, http3_name: :"h3_#{port}"}
      )
      :timer.sleep(100)

      {:ok, conn} = :quic_h3.connect(~c"127.0.0.1", port, %{verify: :verify_none, sync: true})

      # Warm up
      {:ok, sid} = :quic_h3.request(conn, headers)
      wait_h3(conn, sid)
      :timer.sleep(50)

      case mode do
        :http3_single ->
          {us, _} = :timer.tc(fn ->
            for _ <- 1..n_or_streams do
              {:ok, sid} = :quic_h3.request(conn, headers)
              wait_h3(conn, sid)
            end
          end)
          n_or_streams * 1_000_000 / max(us, 1)

        :http3_streams ->
          num_streams = n_or_streams
          reqs_per = div(total, num_streams)

          {us, _} = :timer.tc(fn ->
            for _ <- 1..reqs_per do
              for _ <- 1..num_streams do
                spawn(fn ->
                  {:ok, sid} = :quic_h3.request(conn, headers)
                  wait_h3(conn, sid)
                end)
              end
            end
          end)

          :timer.sleep(500)
          total * 1_000_000 / max(us, 1)
      end
    rescue
      _ -> 0
    end
  end

  defp http2_client(port, n) do
    {:ok, conn} = Mint.HTTP.connect(:https, "127.0.0.1", port, transport_opts: [verify: :verify_none])

    {us, _} = :timer.tc(fn ->
      for _ <- 1..n do
        {:ok, conn, _ref} = Mint.HTTP.request(conn, "GET", path_for(:info), [{"host", "localhost"}])
        recv_http2(conn)
      end
    end)

    Mint.HTTP.close(conn)
    n * 1_000_000 / max(us, 1)
  end

  defp http1_client(port, n) do
    {us, _} = :timer.tc(fn ->
      for _ <- 1..n do
        {:ok, s} = :gen_tcp.connect(~c"127.0.0.1", port, [:binary, active: false])
        :gen_tcp.send(s, "GET #{path_for(:info)} HTTP/1.1\r\nHost: localhost\r\n\r\n")
        :gen_tcp.recv(s, 0, 5000)
        :gen_tcp.close(s)
      end
    end)
    n * 1_000_000 / max(us, 1)
  end

  defp recv_http2(conn) do
    receive do
      {:tcp, ^conn, data} -> data
      {:tcp_closed, ^conn} -> ""
    after
      5000 -> ""
    end
  end

  defp path_for(:info), do: "/v2/info"
  defp path_for(:chain_info), do: "/v2/chain_info"
  defp path_for(:block_explorer), do: "/api/v1/blocks?limit=1"
  defp path_for(:sbtc_relay), do: "/status"

  defp wait_h3(conn, sid) do
    receive do
      {:quic_h3, ^conn, {:response, ^sid, _, _}} -> :ok
      {:quic_h3, ^conn, {:data, ^sid, _, true}} -> :ok
      {:quic_h3, ^conn, {:fin, ^sid}} -> :ok
    after
      5000 -> :error
    end
  end
end
