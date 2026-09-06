defmodule Gale.CLI do
  @moduledoc "Standalone CLI (`gale`) and Mix task (`mix gale`)."

  @version Mix.Project.config()[:version]

  @help """
  gale #{@version} — HTTP/1.1 + HTTP/2 + HTTP/3 client

    gale get     URL
    gale request METHOD URL
    gale hash    FILE [--algo blake3|xxh3]
    gale qpack
    gale nif
    gale version

  Flags:
    --http3             prefer HTTP/3
    --algo A            blake3 (default) or xxh3
    -h, --help

  Install: mix gale.install
    Linux/macOS: ~/.local/bin
    Windows:     %LOCALAPPDATA%\\elixcoder\\bin
    Override:    ELIXCODER_BIN
  """

  def main(args), do: main(args, halt: !mix?())

  def main(args, opts) do
    _ = Application.ensure_all_started(:gale)

    {parsed, rest, _} =
      OptionParser.parse(args,
        strict: [http3: :boolean, algo: :string, help: :boolean, version: :boolean],
        aliases: [h: :help, v: :version]
      )

    result =
      cond do
        parsed[:help] == true ->
          info(@help)
          :ok

        parsed[:version] == true or rest == ["version"] ->
          info("gale #{@version}")
          :ok

        rest == [] ->
          info(@help)
          :ok

        true ->
          dispatch(rest, parsed)
      end

    finish(result, Keyword.get(opts, :halt, false))
  end

  defp dispatch(["get", url | _], parsed) do
    print_http(Gale.request(:get, url, http_opts(parsed)))
  end

  defp dispatch(["request", method, url | _], parsed) do
    m = method |> String.downcase() |> String.to_existing_atom()
    print_http(Gale.request(m, url, http_opts(parsed)))
  end

  defp dispatch(["hash", file | _], parsed) do
    bin = File.read!(file)

    case parsed[:algo] || "blake3" do
      "blake3" ->
        info(Base.encode16(Gale.blake3(bin), case: :lower))
        :ok

      "xxh3" ->
        info(Integer.to_string(Gale.xxh3(bin)))
        :ok

      other ->
        err("unknown algo #{other}")
        {:error, :algo}
    end
  end

  defp dispatch(["qpack" | _], _) do
    case Gale.qpack_encode([{":method", "GET"}, {":path", "/"}]) do
      {:ok, bin} ->
        info(Base.encode16(bin, case: :lower))
        :ok

      other ->
        err(inspect(other))
        {:error, other}
    end
  end

  defp dispatch(["nif" | _], _) do
    info("nif=#{Gale.nif_loaded?()}")
    :ok
  end

  defp dispatch(_, _) do
    info(@help)
    :ok
  end

  defp http_opts(parsed) do
    if parsed[:http3], do: [protocols: [:http3, :http2, :http1]], else: []
  end

  defp print_http({:ok, resp}) do
    status = Map.get(resp, :status)
    body = Map.get(resp, :body) || ""
    IO.puts(:stderr, "HTTP #{status}")
    if is_binary(body), do: IO.binwrite(:stdio, body)
    :ok
  end

  defp print_http({:error, e}) do
    err(inspect(e))
    {:error, e}
  end

  defp info(msg), do: IO.puts(msg)
  defp err(msg), do: IO.puts(:stderr, msg)

  defp mix? do
    Code.ensure_loaded?(Mix.Project) and function_exported?(Mix.Project, :get, 0)
  rescue
    _ -> false
  end

  defp finish(:ok, false), do: :ok
  defp finish({:error, _} = e, false), do: e
  defp finish(:ok, true), do: System.halt(0)
  defp finish(_, true), do: System.halt(1)
end
