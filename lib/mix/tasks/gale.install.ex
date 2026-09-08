defmodule Mix.Tasks.Gale.Install do
  @moduledoc "Install gale: Burrito single binary if possible, else escript."
  use Mix.Task
  @shortdoc "Install the gale CLI (single binary or escript)"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("compile")

    case maybe_burrito() do
      {:ok, src} ->
        dest = Gale.CLI.Paths.install_bin(src, "gale")
        Mix.shell().info("installed single binary #{dest}")

      :error ->
        Mix.Task.run("gale.build")
        Mix.Task.run("escript.build")
        dest = Gale.CLI.Paths.install_escript("gale")
        priv = Gale.CLI.Paths.copy_priv(:gale)
        Mix.shell().info("installed escript #{dest} (needs escript on PATH)")
        Mix.shell().info("NIFs in #{priv}")
        Mix.shell().info("for a single binary: zig 0.15 + xz, then mix gale.binary")
    end

    Mix.shell().info("bin dir #{Gale.CLI.Paths.bin_dir()}")
  end

  defp maybe_burrito do
    Mix.Task.run("gale.binary")

    case Path.wildcard("burrito_out/gale_*") do
      [f | _] -> {:ok, f}
      _ -> :error
    end
  rescue
    e ->
      Mix.shell().error("burrito: #{Exception.message(e)}")
      :error
  end
end
