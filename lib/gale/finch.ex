defmodule Gale.Finch do
  @moduledoc """
  Drop-in for `Finch`. Same `start_link/1` and `request/3`; HTTP/3 when the
  request URL uses `https` and `protocols: [:http3]` is in Finch pool config
  or request opts.
  """

  def start_link(opts), do: Finch.start_link(opts)

  def child_spec(opts) do
    %{
      id: Keyword.get(opts, :name, __MODULE__),
      start: {__MODULE__, :start_link, [opts]},
      type: :supervisor
    }
  end

  defdelegate build(method, url, headers \\ [], body \\ nil, opts \\ []), to: Finch
  defdelegate stream(req, name, acc, fun, opts \\ []), to: Finch

  def request(req, name, opts \\ [])

  def request(%Finch.Request{} = req, name, opts) do
    if Keyword.get(opts, :http3, false) do
      url = %URI{
        scheme: to_string(req.scheme),
        host: req.host,
        port: req.port,
        path: req.path,
        query: req.query
      }

      Gale.HTTP.request(req.method, URI.to_string(url),
        headers: req.headers,
        body: req.body || "",
        protocols: [:http3]
      )
      |> to_finch_result()
    else
      Finch.request(req, name, opts)
    end
  end

  def request!(req, name, opts \\ []) do
    case request(req, name, opts) do
      {:ok, resp} -> resp
      {:error, e} -> raise e
    end
  end

  defp to_finch_result({:ok, %{status: s, headers: h, body: b}}) do
    {:ok, %Finch.Response{status: s, headers: h, body: b, trailers: []}}
  end

  defp to_finch_result({:error, reason}), do: {:error, reason}
end
