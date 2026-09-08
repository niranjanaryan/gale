defmodule Mix.Tasks.Gale.Bench.Stacks do
  @moduledoc false
  use Mix.Task

  @shortdoc "Stacks-specific HTTP/3 benchmarks"

  @impl true
  def run(_args) do
    Mix.Task.run("app.start")
    Gale.Bench.Stacks.run()
  end
end
