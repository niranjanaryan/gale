defmodule Mix.Tasks.Gale.Binary do
  @moduledoc "Build a Burrito single-file CLI (ERTS inside). Needs zig + xz."
  use Mix.Task
  @shortdoc "Single-file gale binary (Burrito)"

  @impl Mix.Task
  def run(_args) do
    Mix.Task.run("gale.build")
    Mix.Task.run("compile")
    System.put_env("BURRITO_TARGET", System.get_env("BURRITO_TARGET") || host_target())
    Mix.Task.run("release", ["gale", "--overwrite"])
  end

  defp host_target do
    case :os.type() do
      {:win32, _} ->
        "windows"

      {:unix, :darwin} ->
        if arch() =~ "aarch64" or arch() =~ "arm64", do: "macos_silicon", else: "macos"

      _ ->
        if arch() =~ "aarch64" or arch() =~ "arm64", do: "linux_aarch64", else: "linux"
    end
  end

  defp arch, do: :erlang.system_info(:system_architecture) |> to_string()
end
