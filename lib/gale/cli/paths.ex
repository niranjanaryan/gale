defmodule Gale.CLI.Paths do
  @moduledoc false

  def windows?, do: match?({:win32, _}, :os.type())

  def bin_dir do
    System.get_env("ELIXCODER_BIN") || System.get_env("GALE_BIN") || default_bin()
  end

  def priv_dir(app \\ :gale) do
    env = System.get_env("#{app |> Atom.to_string() |> String.upcase()}_PRIV")
    env || default_priv(app)
  end

  def install_escript(name) when is_binary(name) do
    dest_dir = bin_dir()
    File.mkdir_p!(dest_dir)
    src = Path.join(File.cwd!(), name)

    unless File.exists?(src) do
      raise ArgumentError, "escript not found at #{src}; run mix escript.build"
    end

    dest = Path.join(dest_dir, name)
    File.cp!(src, dest)
    unless windows?(), do: File.chmod!(dest, 0o755)

    if windows?() do
      File.write!(dest <> ".bat", "@echo off\r\nescript.exe \"%~dpn0\" %*\r\n")
    end

    dest
  end

  def copy_priv(app) do
    dest = priv_dir(app)
    File.mkdir_p!(dest)
    src = Path.join(Mix.Project.app_path(), "priv")
    if File.dir?(src), do: File.cp_r!(src, dest)
    dest
  end

  def nif_dirs(app, stem) do
    unix = Path.join(Path.expand("~/.#{app}/priv"), stem)
    win = Path.join(priv_dir(app), stem)
    Enum.uniq([win, unix])
  end

  defp default_bin do
    if windows?(),
      do: Path.join(local_app_data(), "elixcoder/bin"),
      else: Path.expand("~/.local/bin")
  end

  defp default_priv(app) do
    name = Atom.to_string(app)

    if windows?() do
      Path.join(local_app_data(), "#{name}/priv")
    else
      Path.expand("~/.#{name}/priv")
    end
  end

  defp local_app_data do
    System.get_env("LOCALAPPDATA") ||
      Path.join(System.get_env("USERPROFILE") || Path.expand("~"), "AppData/Local")
  end
end
