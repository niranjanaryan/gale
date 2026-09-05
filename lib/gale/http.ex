defmodule Gale.HTTP do
  @moduledoc """
  Drop-in HTTP client for Req / Finch / hackney / Mint-style calls.

  H1/H2 go through Req (Finch). H3 goes through `:quic_h3` when
  `protocols: [:http3]` (or `[:http3, :http2, :http1]`) is set.
  """

  def get(url, opts \\ []), do: request(:get, url, opts)
  def post(url, opts \\ []), do: request(:post, url, opts)
  def put(url, opts \\ []), do: request(:put, url, opts)
  def delete(url, opts \\ []), do: request(:delete, url, opts)
  def head(url, opts \\ []), do: request(:head, url, opts)
  def patch(url, opts \\ []), do: request(:patch, url, opts)

  def get!(url, opts \\ []), do: unwrap!(get(url, opts))
  def post!(url, opts \\ []), do: unwrap!(post(url, opts))

  def request(method, url, opts \\ [])

  def request(method, url, opts) when is_binary(url) or is_struct(url, URI) do
    protocols = Keyword.get(opts, :protocols, [:http1, :http2])
    req_opts = Keyword.drop(opts, [:protocols])

    cond do
      protocols == [:http3] ->
        h3_request(method, url, req_opts)

      :http3 in protocols ->
        case h3_request(method, url, req_opts) do
          {:ok, _} = ok -> ok
          {:error, _} -> req_request(method, url, req_opts)
        end

      true ->
        req_request(method, url, req_opts)
    end
  end

  defp req_request(method, url, opts) do
    Req.request([method: method, url: url] ++ opts)
  end

  defp h3_request(method, url, opts) do
    uri = URI.parse(to_string(url))
    host = uri.host || "localhost"
    port = uri.port || 443
    path = uri.path || "/"
    path = if uri.query, do: path <> "?" <> uri.query, else: path
    method_b = method |> to_string() |> String.upcase()
    body = Keyword.get(opts, :body, "") |> IO.iodata_to_binary()
    extra = Keyword.get(opts, :headers, [])

    headers =
      [
        {":method", method_b},
        {":scheme", uri.scheme || "https"},
        {":path", path},
        {":authority", host_port(host, port)}
      ] ++ normalize_headers(extra)

    verify = Keyword.get(opts, :verify, :verify_none)

    with {:ok, conn} <-
           :quic_h3.connect(String.to_charlist(host), port, %{
             verify: verify,
             sync: true,
             connect_timeout: Keyword.get(opts, :receive_timeout, 5_000)
           }),
         {:ok, sid} <- h3_send(conn, headers, body) do
      resp = await_h3(conn, sid, Keyword.get(opts, :receive_timeout, 5_000))
      _ = :quic_h3.close(conn)
      resp
    end
  end

  defp h3_send(conn, headers, "") do
    :quic_h3.request(conn, bin_headers(headers))
  end

  defp h3_send(conn, headers, body) do
    :quic_h3.request(conn, bin_headers(headers), %{body: body})
  end

  defp bin_headers(hs) do
    Enum.map(hs, fn {k, v} -> {IO.iodata_to_binary(k), IO.iodata_to_binary(to_string(v))} end)
  end

  defp await_h3(conn, sid, timeout) do
    await_h3(conn, sid, timeout, nil, [], [])
  end

  defp await_h3(conn, sid, timeout, status, hdrs, body) do
    receive do
      {:quic_h3, ^conn, {:response, ^sid, st, resp_headers}} ->
        await_h3(conn, sid, timeout, st, resp_headers, body)

      {:quic_h3, ^conn, {:data, ^sid, data, fin?}} ->
        body = [body, data]

        if fin?,
          do: {:ok, h3_resp(status, hdrs, body)},
          else: await_h3(conn, sid, timeout, status, hdrs, body)

      {:quic_h3, ^conn, {:fin, ^sid}} ->
        {:ok, h3_resp(status, hdrs, body)}
    after
      timeout -> {:error, :timeout}
    end
  end

  defp h3_resp(status, hdrs, body) do
    %{
      status: status || 0,
      headers: Enum.map(hdrs, fn {k, v} -> {to_string(k), to_string(v)} end),
      body: IO.iodata_to_binary(body)
    }
  end

  defp host_port(host, 443), do: host
  defp host_port(host, port), do: "#{host}:#{port}"

  defp normalize_headers(headers) do
    Enum.map(headers, fn
      {k, v} -> {to_string(k), to_string(v)}
      {k, v, _} -> {to_string(k), to_string(v)}
    end)
  end

  defp unwrap!({:ok, resp}), do: resp
  defp unwrap!({:error, reason}), do: raise("Gale.HTTP error: #{inspect(reason)}")
end
