defmodule Gale.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    maybe_cli()
    _ = Application.ensure_all_started(:quic)
    _ = Application.ensure_all_started(:hackney)
    Supervisor.start_link([], strategy: :one_for_one, name: Gale.Supervisor)
  end

  defp maybe_cli do
    if System.get_env("RELEASE_NAME") == "gale" do
      args = :init.get_plain_arguments() |> Enum.map(&List.to_string/1)
      Gale.CLI.main(args, halt: true)
    end
  end
end
