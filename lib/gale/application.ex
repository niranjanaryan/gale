defmodule Gale.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    _ = Application.ensure_all_started(:quic)
    _ = Application.ensure_all_started(:hackney)
    Supervisor.start_link([], strategy: :one_for_one, name: Gale.Supervisor)
  end
end
