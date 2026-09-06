defmodule Gale.Plug do
  @moduledoc """
  Plug adapter for Gale HTTP/1.1, HTTP/2, and HTTP/3.

  This module provides a drop-in replacement for `Plug.Cowboy` and `Plug.Adapters.Bandit`,
  allowing any Plug-based application to run on Gale:

      defmodule MyApp do
        use Plug.Builder
        plug :match
        plug :dispatch

        get "/" do
          send_resp(conn, 200, "Hello from Gale!")
        end
      end

  Then start it:

      # Start Gale with your Plug
      children = [
        {Gale.Plug, plug: MyApp, port: 4000}
      ]

      Supervisor.start_link(children, strategy: :one_for_one)

  ## Options

  - `:scheme` - `:http` or `:https` (default: `:http`)
  - `:plug` - The Plug module or `{module, opts}` tuple
  - `:port` - Port to listen on (default: 4000)
  - `:ip` - IP address to bind to
  - `:http3` - Enable HTTP/3 (requires HTTPS with certs)
  - `:certfile` - Path to SSL certificate
  - `:keyfile` - Path to SSL private key

  ## Phoenix Integration

  For Phoenix applications, use `Gale.PhoenixAdapter` instead:

      config :my_app, MyAppWeb.Endpoint,
        adapter: Gale.PhoenixAdapter

  """

  @doc """
  Starts Gale server for the given Plug.
  """
  @spec start_link(keyword()) :: {:ok, pid} | {:error, term}
  def start_link(opts) do
    {:ok, _pid} = Gale.Server.start_link(opts)
  end

  @doc """
  Returns a child_spec for Gale server.

  Use this in your supervision tree:

      children = [
        {Gale.Plug, plug: MyPlug, port: 4000}
      ]
  """
  @spec child_spec(keyword()) :: Supervisor.child_spec()
  def child_spec(opts) when is_list(opts) do
    %{
      id: Keyword.get(opts, :id, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  @doc """
  Returns child specs for HTTP and HTTPS listeners.

  Use this when you need separate HTTP/HTTPS child specs:

      children = Gale.Plug.child_specs(
        plug: MyPlug,
        http: [port: 4000],
        https: [port: 4443, certfile: "cert.pem", keyfile: "key.pem"],
        http3: true
      )
  """
  @spec child_specs(keyword()) :: [Supervisor.child_spec()]
  def child_specs(opts) when is_list(opts) do
    plug = Keyword.fetch!(opts, :plug)
    http3 = Keyword.get(opts, :http3, false)

    for scheme <- [:http, :https],
        scheme_opts = opts[scheme],
        is_list(scheme_opts) do
      h3 = resolve_http3(http3, scheme, scheme_opts)
      %{
        id: {__MODULE__, scheme},
        start: {__MODULE__, :start_link, [[plug: plug, scheme: scheme] ++ scheme_opts ++ [http3: h3]]}
      }
    end
  end

  defp resolve_http3(true, :https, opts) do
    cert = opts[:certfile] || opts[:cert]
    key = opts[:keyfile] || opts[:key]
    if cert && key, do: [port: opts[:port] || 443, certfile: cert, keyfile: key], else: false
  end

  defp resolve_http3(opts, _scheme, _http_opts) when is_list(opts), do: opts
  defp resolve_http3(_http3, _, _), do: false
end
