defmodule Mix.Tasks.Gale.Build do
  @moduledoc false
  use Mix.Task

  @shortdoc "Builds the gale Zig NIF shared library"
  @recursive true

  @impl Mix.Task
  def run(_args) do
    app_path = Mix.Project.app_path()
    priv_dir = Path.join(app_path, "priv")
    File.mkdir_p!(priv_dir)
    so_path = Path.join(priv_dir, "gale_nif.so")
    src = "native/zig/gale.zig"

    so_ok? =
      match?({:ok, %{size: s}} when s > 1024, File.stat(so_path))

    need_build =
      not so_ok? or
        (File.exists?(src) and newer?(src, so_path))

    if need_build do
      Mix.shell().info("Compiling gale Zig NIF...")
      erts_dir = erlang_includes()

      {out, exit} =
        System.cmd(
          "make",
          ["all", "MIX_APP_PATH=#{app_path}", "ERTS_INCLUDE_DIR=#{erts_dir}"],
          stderr_to_stdout: true,
          cd: File.cwd!()
        )

      IO.write(out)
      if exit != 0, do: raise("Failed to compile gale Zig NIF")

      local_so = Path.join(File.cwd!(), "priv/gale_nif.so")

      unless Path.expand(so_path) == Path.expand(local_so) do
        File.mkdir_p!(Path.dirname(local_so))
        File.cp!(so_path, local_so)
      end
    end
  end

  defp erlang_includes do
    if dir = System.get_env("ERTS_INCLUDE_DIR"), do: dir, else: find_erts_include()
  end

  defp find_erts_include do
    case System.find_executable("erl") do
      nil ->
        raise "Could not determine ERTS include dir; set ERTS_INCLUDE_DIR"

      bin ->
        bin
        |> Path.dirname()
        |> walk_up_for_erts(8)
        |> case do
          nil -> raise "Could not determine ERTS include dir; set ERTS_INCLUDE_DIR"
          erts_root -> Path.join(erts_root, "include")
        end
    end
  end

  defp walk_up_for_erts(_dir, 0), do: nil

  defp walk_up_for_erts(dir, n) do
    parent = Path.dirname(dir)

    case Path.wildcard(Path.join(parent, "erts-*")) do
      [] -> walk_up_for_erts(parent, n - 1)
      [erts | _] -> erts
    end
  end

  defp newer?(a, b) do
    case {File.stat(a, time: :posix), File.stat(b, time: :posix)} do
      {{:ok, %File.Stat{mtime: t1}}, {:ok, %File.Stat{mtime: t2}}} -> t1 > t2
      _ -> true
    end
  end
end
