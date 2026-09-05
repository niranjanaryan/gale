defmodule Gale.Plug.Adapter do
  @moduledoc """
  Plug/Phoenix integration surface for HTTP/3 **advertising**, next to Bandit.

  Bandit cannot terminate QUIC. Wire this into a Phoenix endpoint so H1/H2
  responses tell clients where H3 lives (typically Caddy on UDP/443):

      plug Gale.Plug.AltSvc, host: "example.com", port: 443

  `child_spec/1` starts nothing QUIC-related; it exists so an endpoint
  supervisor can list this adapter next to `{Bandit, plug: ...}` without
  forking Bandit.
  """

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]},
      type: :worker
    }
  end

  def start_link(opts) do
    Agent.start_link(fn -> Map.new(opts) end, name: __MODULE__)
  end

  @doc "RFC 9114 Alt-Svc value for HTTP/3 on `host:port`."
  def alt_svc(host, port \\ 443) when is_binary(host) and is_integer(port) do
    ~s(h3="#{host}:#{port}"; ma=86400)
  end

  @doc "Keyword options Bandit should keep using for H1/H2."
  def bandit_options(opts \\ []) do
    Keyword.merge(
      [
        thousand_island_options: [num_acceptors: 100],
        http_options: [],
        websocket_options: []
      ],
      opts
    )
  end
end

defmodule Gale.Plug.AltSvc do
  @moduledoc "Injects `alt-svc: h3=\":port\"` on every Plug response."
  @behaviour Plug

  @impl Plug
  def init(opts), do: opts

  @impl Plug
  def call(conn, opts) do
    host = Keyword.get(opts, :host) || conn.host
    port = Keyword.get(opts, :port, 443)
    Plug.Conn.put_resp_header(conn, "alt-svc", Gale.Plug.Adapter.alt_svc(host, port))
  end
end
