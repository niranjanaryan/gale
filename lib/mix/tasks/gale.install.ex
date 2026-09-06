defmodule Mix.Tasks.Gale.Install do
  @moduledoc "Build escript + NIFs and install `gale` to ~/.local/bin."
  use Mix.Task
  @shortdoc "Install the gale CLI"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("gale.build")
    Mix.Task.run("compile")
    Mix.Task.run("escript.build")

    bin_dir = Path.expand("~/.local/bin")
    priv_dir = Path.expand("~/.gale/priv")
    File.mkdir_p!(bin_dir)
    File.mkdir_p!(priv_dir)

    escript = Path.join(File.cwd!(), "gale")
    File.cp!(escript, Path.join(bin_dir, "gale"))
    File.chmod!(Path.join(bin_dir, "gale"), 0o755)

    app_priv = Path.join(Mix.Project.app_path(), "priv")

    if File.dir?(app_priv) do
      File.cp_r!(app_priv, priv_dir)
    end

    Mix.shell().info("installed #{Path.join(bin_dir, "gale")}")
    Mix.shell().info("NIFs in #{priv_dir}")
    Mix.shell().info("ensure #{bin_dir} is on PATH")
  end
end
