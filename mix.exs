defmodule Gale.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/niranjanaryan/gale"

  def project do
    [
      app: :gale,
      version: @version,
      elixir: "~> 1.17",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      aliases: aliases(),
      deps: deps(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: "https://hex.pm/packages/gale",
      name: "Gale"
    ]
  end

  def cli do
    [preferred_envs: [bench: :dev, docs: :dev]]
  end

  def application do
    [
      mod: {Gale.Application, []},
      extra_applications: [:logger, :crypto, :ssl, :inets, :public_key]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:bandit, "~> 1.6"},
      {:plug, "~> 1.16"},
      {:hpax, "~> 1.0"},
      {:finch, "~> 0.19"},
      {:req, "~> 0.5"},
      {:quic, "~> 1.8"},
      {:hackney, "~> 4.5"},
      {:telemetry, "~> 1.0"},
      {:plug_cowboy, "~> 2.7", optional: true},
      {:quiver, "~> 0.4", optional: true},
      {:benchee, "~> 1.3", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.38", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      test: ["gale.build", "test"],
      bench: ["gale.build", "gale.bench"]
    ]
  end

  defp description do
    "Phoenix adapter for HTTP/1.1, HTTP/2, and HTTP/3 (QUIC). Bandit for TCP, quic_h3 for UDP."
  end

  defp docs do
    [
      main: "Gale",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: [
        "README.md",
        "guides/phoenix.md",
        "ECOSYSTEM.md",
        "benchmark/RESULTS.md",
        "CHANGELOG.md",
        "LICENSE",
        "FUNDING.md",
        "PUBLISH.md"
      ],
      groups_for_extras: [
        Guides: ["guides/phoenix.md", "ECOSYSTEM.md"],
        Project: ["CHANGELOG.md", "LICENSE", "FUNDING.md", "benchmark/RESULTS.md"]
      ],
      groups_for_modules: [
        Phoenix: [Gale.PhoenixAdapter, Gale.Server, Gale.Plug.Compat, Gale.Plug.AltSvc],
        Client: [Gale.HTTP, Gale.Finch, Gale.Req, Gale.Hackney],
        HTTP3: [Gale.HTTP3.Listener, Gale.HTTP3.Handler, Gale.Conn.H3],
        Codec: [Gale.Native, Gale.Elixir]
      ]
    ]
  end

  defp package do
    [
      name: "gale",
      maintainers: ["Niranjan Aryan"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md",
        "Sponsor" => "https://github.com/sponsors/niranjanaryan",
        "HexDocs" => "https://hexdocs.pm/gale",
        "Benchmarks" => "#{@source_url}/blob/main/benchmark/RESULTS.md"
      },
      files: [
        "lib",
        "native/zig",
        "native/rust/src",
        "native/rust/Cargo.toml",
        "native/rust/Cargo.lock",
        "Makefile",
        "mix.exs",
        "mix.lock",
        "README.md",
        "LICENSE",
        "CHANGELOG.md",
        "FUNDING.md",
        "guides",
        "ECOSYSTEM.md",
        "benchmark/RESULTS.md",
        ".formatter.exs"
      ],
      exclude_patterns: [~r"\.so$", ~r"native/rust/target"]
    ]
  end
end
