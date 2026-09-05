defmodule Gale.HTTP3.Listener do
  @moduledoc false
  use GenServer

  def start_link({port, plug, opts}) do
    GenServer.start_link(__MODULE__, {port, plug, opts})
  end

  @impl true
  def init({port, plug, opts}) do
    certfile = Keyword.get(opts, :certfile) || Keyword.get(opts, :cert)
    keyfile = Keyword.get(opts, :keyfile) || Keyword.get(opts, :key)

    if is_nil(certfile) or is_nil(keyfile) do
      {:stop, {:error, :http3_requires_certfile_and_keyfile}}
    else
      name = Keyword.get(opts, :http3_name, :"gale_h3_#{port}")
      cert = load_cert(certfile)
      key = load_key(keyfile)

      handler = fn quic, stream_id, method, path, headers ->
        Gale.HTTP3.Handler.call(plug, quic, stream_id, method, path, headers, port)
      end

      case :quic_h3.start_server(name, port, %{cert: cert, key: key, handler: handler}) do
        {:ok, _} -> {:ok, %{name: name, port: port}}
        {:error, reason} -> {:stop, reason}
      end
    end
  end

  @impl true
  def terminate(_reason, %{name: name}) do
    _ = :quic_h3.stop_server(name)
    :ok
  end

  def terminate(_, _), do: :ok

  defp load_cert(path) when is_binary(path) do
    case File.read(path) do
      {:ok, pem} ->
        pem
        |> :public_key.pem_decode()
        |> Enum.find_value(fn
          {:Certificate, der, _} -> der
          _ -> nil
        end) || raise "no certificate in #{path}"

      {:error, _} ->
        path
    end
  end

  defp load_key(path) when is_binary(path) do
    [entry | _] = path |> File.read!() |> :public_key.pem_decode()
    :public_key.pem_entry_decode(entry)
  end

  defp load_key(key), do: key
end

defmodule Gale.HTTP3.Handler do
  @moduledoc false

  def call(plug, quic, stream_id, method, path, headers, port) do
    {plug_mod, plug_opts} = normalize_plug(plug)
    method = to_string(method)
    path = to_string(path)
    {path_only, qs} = split_qs(path)
    host = header(headers, ":authority") || header(headers, "host") || "localhost"
    req_headers = Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)

    uri = %URI{
      scheme: "https",
      host: host_only(host),
      port: port,
      path: path_only,
      query: qs
    }

    state = %Gale.Conn.H3{quic: quic, stream_id: stream_id, body: "", peer: nil}

    conn =
      Plug.Conn.Adapter.conn({Gale.Conn.H3, state}, method, uri, {127, 0, 0, 1}, req_headers)

    _ = plug_mod.call(conn, plug_mod.init(plug_opts))
    :ok
  rescue
    e ->
      :ok =
        :quic_h3.send_response(quic, stream_id, 500, [
          {<<"content-type">>, <<"text/plain">>}
        ])

      :ok = :quic_h3.send_data(quic, stream_id, Exception.message(e), true)
      :ok
  end

  defp normalize_plug({mod, opts}), do: {mod, opts}
  defp normalize_plug(mod) when is_atom(mod), do: {mod, []}

  defp split_qs(path) do
    case String.split(path, "?", parts: 2) do
      [p] -> {p, nil}
      [p, q] -> {p, q}
    end
  end

  defp header(headers, name) do
    Enum.find_value(headers, fn
      {k, v} -> if to_string(k) == name, do: to_string(v)
    end)
  end

  defp host_only(host) do
    host |> to_string() |> String.split(":") |> hd()
  end
end
