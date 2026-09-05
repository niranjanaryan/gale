defmodule Gale.Req do
  @moduledoc """
  Drop-in for `Req`. `Gale.Req.get/2` is `Req.get/2`. Pass `protocols: [:http3]`
  to force HTTP/3 via `Gale.HTTP`.
  """

  def get(url, opts \\ []), do: request(Keyword.merge(opts, method: :get, url: url))
  def post(url, opts \\ []), do: request(Keyword.merge(opts, method: :post, url: url))
  def put(url, opts \\ []), do: request(Keyword.merge(opts, method: :put, url: url))
  def delete(url, opts \\ []), do: request(Keyword.merge(opts, method: :delete, url: url))

  def get!(url, opts \\ []), do: unwrap!(get(url, opts))
  def post!(url, opts \\ []), do: unwrap!(post(url, opts))

  def request(opts) when is_list(opts) do
    protocols = Keyword.get(opts, :protocols, [:http1, :http2])
    url = Keyword.fetch!(opts, :url)
    method = Keyword.get(opts, :method, :get)
    rest = Keyword.drop(opts, [:protocols])

    if :http3 in List.wrap(protocols) and protocols == [:http3] do
      case Gale.HTTP.request(method, url, rest ++ [protocols: [:http3]]) do
        {:ok, %{status: s, headers: h, body: b}} ->
          {:ok, %Req.Response{status: s, headers: headers_map(h), body: b}}

        {:error, reason} ->
          {:error, reason}
      end
    else
      Req.request(rest)
    end
  end

  defdelegate new(opts \\ []), to: Req
  defdelegate default_options(opts), to: Req

  defp headers_map(list) do
    Map.new(list, fn {k, v} -> {k, List.wrap(v)} end)
  end

  defp unwrap!({:ok, resp}), do: resp
  defp unwrap!({:error, reason}), do: raise("Gale.Req error: #{inspect(reason)}")
end
