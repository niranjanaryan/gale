defmodule GaleListenerConfigTest do
  use ExUnit.Case, async: true

  defmodule ResponsePlug do
    @behaviour Plug

    def init(opts), do: opts

    def call(conn, opts) do
      Plug.Conn.send_resp(conn, 200, Keyword.get(opts, :body, "ok"))
    end
  end

  for adapter <- [Gale.PhoenixAdapter, Gale.Plug] do
    describe "#{inspect(adapter)} HTTP/HTTPS configuration" do
      @adapter adapter

      test "explicit HTTP/3 options create one H3 child, under HTTPS" do
        h3 = [port: 9443, certfile: "h3-cert.pem", keyfile: "h3-key.pem"]
        [http, https] = listener_options(@adapter, http3: h3)

        assert http[:http3] == false
        assert https[:http3] == h3

        assert {:ok, {_, http_children}} = Gale.Server.init(http)
        assert {:ok, {_, https_children}} = Gale.Server.init(https)
        assert Enum.count(http_children ++ https_children, &(&1.id == Gale.HTTP3.Listener)) == 1
      end

      test "http3: true reuses HTTPS credentials and port without enabling HTTP" do
        [http, https] = listener_options(@adapter, http3: true)

        assert http[:http3] == false
        assert https[:http3] == [port: 4443, certfile: "cert.pem", keyfile: "key.pem"]
      end

      test "omitted or disabled HTTP/3 leaves both listeners TCP-only" do
        for config <- [[], [http3: false]] do
          assert Enum.all?(listener_options(@adapter, config), &(&1[:http3] == false))
        end
      end

      test "an HTTP-only endpoint does not start H3 from explicit options" do
        config = [
          otp_app: :gale,
          plug: ResponsePlug,
          http: [port: 4000],
          http3: [port: 9443, certfile: "cert.pem", keyfile: "key.pem"]
        ]

        [spec] = child_specs(@adapter, config)
        {_, :start_link, [opts]} = spec.start
        assert opts[:scheme] == :http
        assert opts[:http3] == false
      end
    end
  end

  test "Phoenix fills omitted H3 values from HTTPS without changing explicit values" do
    [http, https] = listener_options(Gale.PhoenixAdapter, http3: [port: 9443])

    assert http[:http3] == false
    assert https[:http3] == [keyfile: "key.pem", certfile: "cert.pem", port: 9443]
  end

  test "TCP-only servers preserve Plug options and do not inject Alt-Svc" do
    for http3 <- [nil, false] do
      opts = [plug: {ResponsePlug, body: "configured"}, port: 0]
      opts = if is_nil(http3), do: opts, else: Keyword.put(opts, :http3, http3)
      response = tcp_response(opts)

      assert response.status == 200
      assert response.body == "configured"
      assert Req.Response.get_header(response, "alt-svc") == []
    end
  end

  test "explicit H3 port overrides the TCP port and http3_port in Alt-Svc" do
    opts = [
      plug: {ResponsePlug, body: "configured"},
      port: 0,
      http3_port: 8443,
      http3: [port: 9443, certfile: "cert.pem", keyfile: "key.pem"]
    ]

    # Exercise the TCP child over a real socket without starting a QUIC listener.
    # This checks advertisement only, not HTTP/3 negotiation.
    response = tcp_response(opts)

    assert response.status == 200
    assert response.body == "configured"
    assert Req.Response.get_header(response, "alt-svc") == [~s(h3="127.0.0.1:9443"; ma=86400)]
  end

  test "http3: true advertises http3_port when supplied" do
    response = tcp_response(plug: ResponsePlug, port: 0, http3: true, http3_port: 8443)

    assert Req.Response.get_header(response, "alt-svc") == [~s(h3="127.0.0.1:8443"; ma=86400)]
  end

  defp listener_options(adapter, config) do
    defaults = [
      otp_app: :gale,
      plug: ResponsePlug,
      http: [port: 4000],
      https: [port: 4443, certfile: "cert.pem", keyfile: "key.pem"]
    ]

    adapter
    |> child_specs(Keyword.merge(defaults, config))
    |> Enum.map(fn %{start: {_, :start_link, [opts]}} -> opts end)
  end

  defp child_specs(Gale.PhoenixAdapter, config),
    do: Gale.PhoenixAdapter.child_specs(ResponsePlug, config)

  defp child_specs(Gale.Plug, config), do: Gale.Plug.child_specs(config)

  defp tcp_response(opts) do
    {:ok, {_, [bandit | _]}} = Gale.Server.init(opts)
    bandit = start_supervised!(Supervisor.child_spec(bandit, id: make_ref()))
    {:ok, {_, port}} = ThousandIsland.listener_info(bandit)

    Req.get!("http://127.0.0.1:#{port}/", retry: false, redirect: false)
  end
end
