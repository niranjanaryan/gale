defmodule Mix.Tasks.Gale.Install do
  @moduledoc "Build escript + NIFs and install `gale` for Linux, macOS, and Windows."
  use Mix.Task
  @shortdoc "Install the gale CLI (all OS)"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("gale.build")
    Mix.Task.run("compile")
    Mix.Task.run("escript.build")

    dest = Gale.CLI.Paths.install_escript("gale")
    priv = Gale.CLI.Paths.copy_priv(:gale)
    Mix.shell().info("installed #{dest}")
    Mix.shell().info("NIFs in #{priv}")
    Mix.shell().info(path_hint())
  end

  defp path_hint do
    dir = Gale.CLI.Paths.bin_dir()

    if Gale.CLI.Paths.windows?() do
      "add #{dir} to PATH (Windows: System Properties → Environment Variables)"
    else
      "ensure #{dir} is on PATH"
    end
  end
end
