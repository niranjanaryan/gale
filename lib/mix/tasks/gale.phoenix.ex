defmodule Mix.Tasks.Gale.Phoenix do
  @moduledoc """
  Configures a Phoenix endpoint to use Gale for HTTP/1.1, HTTP/2, and HTTP/3.

      mix gale.phoenix
      mix gale.phoenix --endpoint MyAppWeb.Endpoint

  Sets `adapter: Gale.PhoenixAdapter` in `config/config.exs` and prints the
  `:http3` snippet for `config/runtime.exs`.
  """
  use Mix.Task

  @shortdoc "Use Gale as the Phoenix endpoint adapter (QUIC/HTTP3)"

  @impl Mix.Task
  def run(args) do
    {opts, _, _} = OptionParser.parse(args, strict: [endpoint: :string])
    config_path = "config/config.exs"

    unless File.exists?(config_path) do
      Mix.raise("no #{config_path} — run this from a Phoenix app root")
    end

    src = File.read!(config_path)

    src =
      String.replace(
        src,
        "adapter: Bandit.PhoenixAdapter",
        "adapter: Gale.PhoenixAdapter"
      )

    src =
      String.replace(
        src,
        "adapter: Phoenix.Endpoint.Cowboy2Adapter",
        "adapter: Gale.PhoenixAdapter"
      )

    File.write!(config_path, src)
    Mix.shell().info("Set adapter: Gale.PhoenixAdapter in #{config_path}")

    Mix.shell().info("""

    Add Gale to mix.exs:

        {:gale, path: "../gale"}   # or {:gale, "~> 0.1"}

    Optional HTTP/3 in config/runtime.exs:

        config :#{Mix.Project.config()[:app]}, #{opts[:endpoint] || "YourAppWeb.Endpoint"},
          http3: [
            port: String.to_integer(System.get_env("GALE_HTTP3_PORT", "443")),
            certfile: System.get_env("SSL_CERT_PATH"),
            keyfile: System.get_env("SSL_KEY_PATH")
          ]

    UDP #{443} must be open. LiveView still uses Bandit websockets on TCP.
    """)
  end
end
