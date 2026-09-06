defmodule Gale do
  @moduledoc """
  Drop-in HTTP/1.1 + HTTP/2 + HTTP/3 for Phoenix, Bandit, Finch, Req, Cowboy, and hackney.

  ## Server (replaces Bandit / Cowboy)

      {Gale, plug: MyPlug, port: 4000}
      {Gale, plug: MyPlug, port: 443, scheme: :https, certfile: "...", keyfile: "...", http3: true}

      config :app, AppWeb.Endpoint, adapter: Gale.PhoenixAdapter

  ## Client (replaces Req / Finch / hackney)

      Gale.get("https://example.com")
      Gale.get("https://example.com", protocols: [:http3, :http2, :http1])
      {Gale.Finch, name: MyFinch}
      Gale.Hackney.get(url)

  H1/H2 still run on Bandit and Finch. H3 uses Hex `quic` (`quic_h3`) plus the
  Zig QPACK NIF. Production H3 in front of Phoenix can still terminate at Caddy;
  in-VM H3 is `http3: true` with certs.
  """

  def qpack_encode(headers) do
    Gale.Native.qpack_encode(headers)
  rescue
    ErlangError -> Gale.Elixir.qpack_encode(headers)
  end

  def qpack_decode(bin) do
    Gale.Native.qpack_decode(bin)
  rescue
    ErlangError -> {:error, :nif_not_loaded}
  end

  defdelegate h3_frame_encode(kind, payload), to: Gale.Native
  defdelegate h3_frame_decode(bin), to: Gale.Native
  defdelegate quic_varint_encode(n), to: Gale.Native
  defdelegate quic_varint_decode(bin), to: Gale.Native
  defdelegate quic_parse_long_header(bin), to: Gale.Native
  defdelegate blake3(bin), to: Gale.Native
  defdelegate xxh3(bin), to: Gale.Native

  def child_spec(opts), do: Gale.Server.child_spec(opts)
  def start_link(opts), do: Gale.Server.start_link(opts)

  defdelegate get(url, opts \\ []), to: Gale.HTTP
  defdelegate post(url, opts \\ []), to: Gale.HTTP
  defdelegate put(url, opts \\ []), to: Gale.HTTP
  defdelegate delete(url, opts \\ []), to: Gale.HTTP
  defdelegate head(url, opts \\ []), to: Gale.HTTP
  defdelegate patch(url, opts \\ []), to: Gale.HTTP
  defdelegate get!(url, opts \\ []), to: Gale.HTTP
  defdelegate post!(url, opts \\ []), to: Gale.HTTP
  defdelegate request(method, url, opts \\ []), to: Gale.HTTP

  def nif_loaded? do
    match?({:ok, _}, qpack_encode([{":method", "GET"}]))
  rescue
    ErlangError -> false
  end
end
