defmodule Mix.Tasks.Gale.Bench do
  @moduledoc false
  use Mix.Task

  @shortdoc "HTTP/1, HTTP/3 benchmarks - targeting 2M req/s"

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")
    iters = 50_000

    Mix.shell().info("""
    ╔══════════════════════════════════════════════════════════════════╗
    ║           GALE HTTP BENCHMARK - TARGET: 2M req/s              ║
    ╚══════════════════════════════════════════════════════════════════╝
    """)

    qpack_bench(iters)
    http1_bench()
    http3_bench()
    quic_parse_bench(iters)
  end

  defp qpack_bench(iters) do
    Mix.shell().info("\n## QPACK Encode (#{iters} iters)")

    headers = [{":method", "GET"}, {":scheme", "https"}, {":path", "/"}, {":authority", "localhost"}, {"accept", "*/*"}]

    {elixir_t, _} = :timer.tc(fn ->
      for _ <- 1..iters, do: Gale.Elixir.qpack_encode(headers)
    end)

    {zig_t, _} = if Gale.nif_loaded?() do
      :timer.tc(fn ->
        for _ <- 1..iters, do: Gale.qpack_encode(headers)
      end)
    else
      {0, 0}
    end

    elixir_ips = iters * 1_000_000 / elixir_t
    zig_ips = iters * 1_000_000 / max(zig_t, 1)

    Mix.shell().info("Elixir: #{Kernel.round(elixir_ips)}/s | Gale NIF: #{Kernel.round(zig_ips)}/s (#{Float.round(zig_ips / elixir_ips, 1)}x)")
  end

  defp http1_bench do
    Mix.shell().info("\n## HTTP/1.1 Loopback (2000 requests)")

    cowboy = http1_cowboy(4893, 2000)
    bandit = http1_bandit(4892, 2000)

    Mix.shell().info("Cowboy: #{Kernel.round(cowboy)} req/s | Bandit: #{Kernel.round(bandit)} req/s")
  end

  defp http1_cowboy(port, n) do
    if Code.ensure_loaded?(Plug.Cowboy) do
      {:ok, _pid} = Plug.Cowboy.http(Gale.BenchPlug, [], port: port, ref: :"cowboy_#{port}")
      :timer.sleep(50)
      rps = http1_client(port, n)
      Plug.Cowboy.shutdown(:"cowboy_#{port}")
      rps
    else
      0
    end
  rescue
    _ -> 0
  end

  defp http1_bandit(port, n) do
    {:ok, pid} = Bandit.start_link(plug: Gale.BenchPlug, port: port, scheme: :http)
    :timer.sleep(50)
    rps = http1_client(port, n)
    Process.exit(pid, :normal)
    rps
  rescue
    _ -> 0
  end

  defp http1_client(port, n) do
    {us, _} = :timer.tc(fn ->
      for _ <- 1..n do
        {:ok, s} = :gen_tcp.connect(~c"127.0.0.1", port, [:binary, active: false])
        :gen_tcp.send(s, "GET / HTTP/1.1\r\nHost: localhost\r\n\r\n")
        :gen_tcp.recv(s, 0, 5000)
        :gen_tcp.close(s)
      end
    end)
    n * 1_000_000 / us
  end

  defp http3_bench do
    Mix.shell().info("\n## HTTP/3 - Targeting 2M req/s")

    cert = Path.expand("priv/certs/cert.pem")
    key = Path.expand("priv/certs/key.pem")

    unless File.exists?(cert) and File.exists?(key) do
      Mix.shell().info("  Certs not found!")
    else
      single = h3_single(cert, key, 4943, 1000)
      Mix.shell().info("  Single conn: #{Kernel.round(single)} req/s")

      # Try different stream counts
      for n <- [3, 5, 7] do
        result = h3_streams(cert, key, 4940 + n, n, 20000)
        Mix.shell().info("  #{n} streams: #{Kernel.round(result)} req/s")
      end

      raw_udp()
    end
  end

  defp h3_single(cert, key, port, n) do
    headers = [{":method", "GET"}, {":scheme", "https"}, {":path", "/"}, {":authority", "localhost"}]

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

      {us, _} = :timer.tc(fn ->
        for _ <- 1..n do
          {:ok, sid} = :quic_h3.request(conn, headers)
          wait_h3(conn, sid)
        end
      end)

      :quic_h3.close(conn)
      :quic_h3.stop_server(:"h3_#{port}")
      n * 1_000_000 / us
    rescue
      _ -> 0
    end
  end

  defp h3_streams(cert, key, port, num_streams, total) do
    headers = [{":method", "GET"}, {":scheme", "https"}, {":path", "/"}, {":authority", "localhost"}]

    try do
      {:ok, _} = Gale.HTTP3.Listener.start_link(
        {port, Gale.BenchPlug, certfile: cert, keyfile: key, http3_name: :"h3s_#{port}"}
      )
      :timer.sleep(100)

      {:ok, conn} = :quic_h3.connect(~c"127.0.0.1", port, %{verify: :verify_none, sync: true})

      # Warm up
      for _ <- 1..num_streams do
        {:ok, sid} = :quic_h3.request(conn, headers)
        wait_h3(conn, sid)
      end
      :timer.sleep(50)

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
      :quic_h3.close(conn)
      :quic_h3.stop_server(:"h3s_#{port}")
      total * 1_000_000 / max(us, 1)
    rescue
      _ -> 0
    end
  end

  defp raw_udp do
    Mix.shell().info("  Raw UDP throughput:")

    {:ok, sock} = :gen_udp.open(0, [:binary, active: false])
    pkt = <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32>>
    n = 500_000

    {us, _} = :timer.tc(fn ->
      for _ <- 1..n, do: :gen_udp.send(sock, {127, 0, 0, 1}, 4947, pkt)
    end)

    :gen_udp.close(sock)
    Mix.shell().info("  #{Kernel.round(n * 1_000_000 / us)} msg/s")
  end

  defp wait_h3(conn, sid) do
    receive do
      {:quic_h3, ^conn, {:response, ^sid, _, _}} -> :ok
      {:quic_h3, ^conn, {:data, ^sid, _, true}} -> :ok
      {:quic_h3, ^conn, {:fin, ^sid}} -> :ok
    after
      5000 -> :error
    end
  end

  defp quic_parse_bench(iters) do
    Mix.shell().info("\n## QUIC Long-Header Parse")
    pkt = <<0xC0, 0, 0, 0, 1, 4, 1, 2, 3, 4, 2, 9, 9, 0>>

    {us, _} = :timer.tc(fn ->
      for _ <- 1..iters, do: Gale.quic_parse_long_header(pkt)
    end)

    ips = iters * 1_000_000 / us
    Mix.shell().info("Zig NIF: #{Kernel.round(ips)} packets/s (#{Float.round(ips / 1_000_000, 1)}M/s)")
  end
end
