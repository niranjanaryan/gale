defmodule Gale.PhoenixAdapter do
  @moduledoc """
  Phoenix endpoint adapter: HTTP/1.1 + HTTP/2 (Bandit) and HTTP/3 (QUIC).

  Drop-in for `Bandit.PhoenixAdapter`. Phoenix 1.7+ LiveView websockets keep
  working on Bandit. HTTP/3 is extra, on UDP.

      # config/config.exs
      config :my_app, MyAppWeb.Endpoint,
        adapter: Gale.PhoenixAdapter

      # config/runtime.exs (prod)
      config :my_app, MyAppWeb.Endpoint,
        https: [
          port: 443,
          certfile: System.fetch_env!("SSL_CERT_PATH"),
          keyfile: System.fetch_env!("SSL_KEY_PATH")
        ],
        http3: [
          port: 443,
          certfile: System.fetch_env!("SSL_CERT_PATH"),
          keyfile: System.fetch_env!("SSL_KEY_PATH")
        ]

  `:http3` may be `true` (reuse https certs and port), a keyword list, or omitted.
  Responses on H1/H2 include `alt-svc` so browsers upgrade to H3.
  """

  @doc "Gale server supervisor for `scheme` (`:http` or `:https`) on the endpoint."
  def gale_pid(endpoint, scheme \\ :http) do
    endpoint
    |> Supervisor.which_children()
    |> Enum.find(fn {id, _, _, _} -> id == {endpoint, scheme} end)
    |> case do
      {_, pid, _, _} when is_pid(pid) -> {:ok, pid}
      _ -> {:error, :no_server_found}
    end
  end

  @doc "Bandit process under the Gale supervisor (H1/H2)."
  def bandit_pid(endpoint, scheme \\ :http) do
    with {:ok, sup} <- gale_pid(endpoint, scheme) do
      find_bandit(sup)
    end
  end

  @doc "HTTP/3 listener pid, if started."
  def http3_pid(endpoint, scheme \\ :https) do
    with {:ok, sup} <- gale_pid(endpoint, scheme) do
      find_h3(sup)
    end
  end

  @doc "Bound TCP address/port of the Bandit listener (Phoenix uses this)."
  def server_info(endpoint, scheme) do
    case bandit_pid(endpoint, scheme) do
      {:ok, pid} -> ThousandIsland.listener_info(pid)
      error -> error
    end
  end

  @doc false
  def child_specs(endpoint, config) do
    otp_app = Keyword.fetch!(config, :otp_app)
    plug = resolve_plug(config[:code_reloader], endpoint)
    http3 = Keyword.get(config, :http3)

    for scheme <- [:http, :https], opts = config[scheme], is_list(opts) do
      h3 = merge_http3(http3, scheme, opts)

      ([
         plug: plug,
         display_plug: endpoint,
         scheme: scheme,
         otp_app: otp_app,
         http3: h3
       ] ++ opts)
      |> Gale.Server.child_spec()
      |> Supervisor.child_spec(id: {endpoint, scheme})
    end
  end

  defp merge_http3(nil, _scheme, _opts), do: false
  defp merge_http3(false, _scheme, _opts), do: false

  defp merge_http3(true, scheme, opts) do
    cert = opts[:certfile] || opts[:cert]
    key = opts[:keyfile] || opts[:key]

    if (scheme == :https and cert) && key do
      [port: opts[:port] || 443, certfile: cert, keyfile: key]
    else
      false
    end
  end

  defp merge_http3(h3, _scheme, opts) when is_list(h3) do
    h3
    |> Keyword.put_new(:certfile, opts[:certfile] || opts[:cert])
    |> Keyword.put_new(:keyfile, opts[:keyfile] || opts[:key])
    |> Keyword.put_new(:port, opts[:port] || 443)
  end

  defp find_bandit(sup) do
    sup
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {Bandit, pid, _, _} when is_pid(pid) -> {:ok, pid}
      {{Bandit, _}, pid, _, _} when is_pid(pid) -> {:ok, pid}
      _ -> nil
    end) || {:error, :no_server_found}
  end

  defp find_h3(sup) do
    sup
    |> Supervisor.which_children()
    |> Enum.find_value(fn
      {Gale.HTTP3.Listener, pid, _, _} when is_pid(pid) -> {:ok, pid}
      _ -> nil
    end) || {:error, :no_http3}
  end

  defp resolve_plug(code_reload?, endpoint) do
    if code_reload? &&
         Code.ensure_loaded?(Phoenix.Endpoint.SyncCodeReloadPlug) &&
         function_exported?(Phoenix.Endpoint.SyncCodeReloadPlug, :call, 2) do
      {Phoenix.Endpoint.SyncCodeReloadPlug, {endpoint, []}}
    else
      endpoint
    end
  end
end
