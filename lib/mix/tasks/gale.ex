defmodule Mix.Tasks.Gale do
  @moduledoc "Gale CLI. Same as the `gale` escript."
  use Mix.Task
  @shortdoc "gale get|request|hash|qpack|nif"

  @impl Mix.Task
  def run(args) do
    Mix.Task.run("app.start")
    Gale.CLI.main(args, halt: false)
  end
end
