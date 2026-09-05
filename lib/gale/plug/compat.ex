defmodule Gale.Plug.Compat do
  @moduledoc false
  @behaviour Plug

  @impl Plug
  def init(state), do: state

  @impl Plug
  def call(conn, {plug, opts}) when is_atom(plug) and is_list(opts) do
    dispatch(conn, plug, Keyword.delete(opts, :h3_port), opts)
  end

  def call(conn, {{plug, plug_opts}, opts}) when is_atom(plug) do
    dispatch(conn, plug, plug_opts, opts)
  end

  def call(conn, plug) when is_atom(plug) do
    dispatch(conn, plug, [], [])
  end

  defp dispatch(conn, plug, plug_opts, opts) do
    h3_port = Keyword.get(opts, :h3_port, conn.port || 443)

    conn
    |> Plug.Conn.put_resp_header(
      "alt-svc",
      Gale.Plug.Adapter.alt_svc(conn.host || "localhost", h3_port)
    )
    |> plug.call(plug.init(plug_opts))
  end
end
