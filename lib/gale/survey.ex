defmodule Gale.Survey do
  @moduledoc """
  Runtime probe of BEAM HTTP/QUIC/H3 packages (see `ECOSYSTEM.md`).
  """

  @candidates [
    %{id: :gale, mod: Gale, role: "H3/QPACK Zig NIF + Plug alt-svc (this package)"},
    %{id: :bandit, mod: Bandit, role: "Phoenix default HTTP/1.1 + HTTP/2 server (no H3)"},
    %{id: :cowboy, mod: :cowboy, role: "Ranch HTTP server; H3 historically via quicer NIF"},
    %{id: :plug, mod: Plug, role: "HTTP adapter behaviour (TCP-oriented)"},
    %{id: :mint, mod: Mint.HTTP, role: "Low-level HTTP/1.1 + HTTP/2 client (no H3)"},
    %{id: :finch, mod: Finch, role: "Pooled HTTP client on Mint (no H3)"},
    %{id: :req, mod: Req, role: "High-level HTTP client on Finch (no H3)"},
    %{id: :hackney, mod: :hackney, role: "HTTP/1.1+2+3 client; H3 opt-in via erlang quic"},
    %{id: :quiver, mod: Quiver, role: "Elixir HTTP client with H3 on erlang quic"},
    %{id: :http_fetch, mod: :http_fetch, role: "Fetch API; depends on quic"},
    %{id: :quic, mod: :quic, role: "Pure Erlang QUIC + quic_h3 (RFC 9000/9114)"},
    %{id: :quic_h3, mod: :quic_h3, role: "HTTP/3 API on :quic"},
    %{id: :webtransport, mod: :webtransport, role: "WebTransport over H2/H3"},
    %{id: :livery, mod: :livery, role: "Erlang web framework H1/H2/H3"},
    %{id: :quicer, mod: :quicer, role: "MsQuic NIF (EMQX)"},
    %{id: :quichex, mod: Quichex.Native, role: "Cloudflare quiche Rustler NIF"},
    %{id: :hpax, mod: HPAX, role: "HPACK (HTTP/2 headers), not QPACK"},
    %{id: :thousand_island, mod: ThousandIsland, role: "TCP server under Bandit (no UDP/QUIC)"}
  ]

  def candidates, do: @candidates

  def probe do
    Enum.map(@candidates, fn c ->
      loaded = module_loaded?(c.mod)
      Map.put(c, :loaded, loaded)
    end)
  end

  defp module_loaded?(mod) when is_atom(mod) do
    match?({:module, _}, Code.ensure_loaded(mod))
  end
end
