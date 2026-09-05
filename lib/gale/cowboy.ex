defmodule Gale.Cowboy do
  @moduledoc """
  Drop-in for `Plug.Cowboy.http/3` / `https/3`. Adds `alt-svc` on the plug.
  """

  def http(plug, plug_opts, cowboy_opts \\ []) do
    port = Keyword.get(cowboy_opts, :port, 4000)
    h3_port = Keyword.get(cowboy_opts, :http3_port, port)

    Plug.Cowboy.http(
      Gale.Plug.Compat,
      {plug, Keyword.put(List.wrap(plug_opts), :h3_port, h3_port)},
      cowboy_opts
    )
  end

  def https(plug, plug_opts, cowboy_opts \\ []) do
    port = Keyword.get(cowboy_opts, :port, 4040)
    h3_port = Keyword.get(cowboy_opts, :http3_port, port)

    Plug.Cowboy.https(
      Gale.Plug.Compat,
      {plug, Keyword.put(List.wrap(plug_opts), :h3_port, h3_port)},
      cowboy_opts
    )
  end

  defdelegate shutdown(ref), to: Plug.Cowboy
  defdelegate child_spec(opts), to: Plug.Cowboy
end
