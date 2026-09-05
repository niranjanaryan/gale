defmodule Gale.Server do
  @moduledoc """
  Drop-in for `Bandit.start_link/1` / `{Bandit, opts}`.

  Starts Bandit for HTTP/1.1 and HTTP/2, injects `alt-svc`, and optionally
  starts an HTTP/3 listener via `:quic_h3` when `http3: true` (needs certs).
  """
  use Supervisor
  require Logger

  def child_spec(opts) do
    %{
      id: {__MODULE__, Keyword.get(opts, :port, 4000)},
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts)
  end

  @impl true
  def init(opts) do
    {http3, opts} = Keyword.pop(opts, :http3, false)
    {h3_port, opts} = Keyword.pop(opts, :http3_port, Keyword.get(opts, :port, 4000))
    plug = Keyword.fetch!(opts, :plug)

    wrapped = {Gale.Plug.Compat, {plug, h3_port: h3_port}}
    bandit_opts = Keyword.put(opts, :plug, wrapped)

    bandit = Supervisor.child_spec({Bandit, bandit_opts}, id: Bandit)
    h3_children = h3_child(http3, h3_port, plug, opts)

    :telemetry.execute(
      [:gale, :server, :init],
      %{system_time: System.system_time()},
      %{port: Keyword.get(opts, :port, 4000), http3: h3_children != []}
    )

    if h3_children != [] do
      Logger.info("Gale HTTP/3 (QUIC) on UDP port #{h3_listen_port(http3, h3_port)}")
    end

    Supervisor.init([bandit | h3_children], strategy: :one_for_one)
  end

  defp h3_listen_port(opts, default) when is_list(opts), do: Keyword.get(opts, :port, default)
  defp h3_listen_port(_, default), do: default

  defp h3_child(false, _, _, _), do: []
  defp h3_child(true, port, plug, opts), do: [{Gale.HTTP3.Listener, {port, plug, opts}}]

  defp h3_child(h3_opts, port, plug, opts) when is_list(h3_opts) do
    port = Keyword.get(h3_opts, :port, port)
    merged = Keyword.merge(opts, h3_opts)
    [{Gale.HTTP3.Listener, {port, plug, merged}}]
  end
end
