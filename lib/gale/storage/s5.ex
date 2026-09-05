defmodule Gale.Storage.S5 do
  @moduledoc """
  S5 blob client. Content-addressed with BLAKE3; HTTP to an S5 node.

      Gale.Storage.S5.put(data, endpoint: "http://127.0.0.1:5050")
      Gale.Storage.S5.get(cid, endpoint: "http://127.0.0.1:5050")
  """

  alias Gale.Storage.CID

  def cid(data) when is_binary(data) do
    %CID{hash: Gale.blake3(data), size: byte_size(data), algo: :blake3}
  end

  def put(data, opts) when is_binary(data) do
    cid = Keyword.get_lazy(opts, :cid, fn -> cid(data) end)
    endpoint = Keyword.fetch!(opts, :endpoint)
    url = endpoint <> "/s5/upload"
    headers = [{~c"content-type", ~c"application/octet-stream"}]
    req = {String.to_charlist(url), headers, ~c"application/octet-stream", data}

    case :httpc.request(:post, req, http_opts(opts), []) do
      {:ok, {{_, 200, _}, _, _}} -> {:ok, cid}
      {:ok, {{_, 201, _}, _, _}} -> {:ok, cid}
      {:ok, {{_, code, _}, _, body}} -> {:error, {code, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  def get(%CID{} = cid, opts) do
    endpoint = Keyword.fetch!(opts, :endpoint)
    hex = CID.hex(cid)
    url = endpoint <> "/s5/blob/" <> hex

    case :httpc.request(:get, {String.to_charlist(url), []}, http_opts(opts), []) do
      {:ok, {{_, 200, _}, _, body}} ->
        bin = IO.iodata_to_binary(body)
        Gale.Storage.verify(bin, cid)

      {:ok, {{_, code, _}, _, body}} ->
        {:error, {code, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp http_opts(opts) do
    [timeout: Keyword.get(opts, :timeout, 30_000)]
  end
end
