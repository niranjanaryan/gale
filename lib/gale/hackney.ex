defmodule Gale.Hackney do
  @moduledoc """
  Drop-in for `:hackney`. HTTP/3 is opt-in with `protocols: [:http3 | ...]`
  (hackney 4.x) or via `Gale.HTTP`.
  """

  def get(url, headers \\ [], body \\ "", opts \\ []) do
    request(:get, url, headers, body, opts)
  end

  def request(method, url, headers \\ [], body \\ "", opts \\ []) do
    protocols = Keyword.get(opts, :protocols, [:http1])

    if :http3 in protocols do
      Gale.HTTP.request(method, url,
        headers: headers,
        body: body,
        protocols: protocols,
        receive_timeout: Keyword.get(opts, :recv_timeout, 5_000)
      )
    else
      :hackney.request(method, url, headers, body, opts)
    end
  end
end
