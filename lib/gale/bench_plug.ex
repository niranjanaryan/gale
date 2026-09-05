defmodule Gale.BenchPlug do
  @moduledoc false
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> put_resp_header("alt-svc", Gale.Plug.Adapter.alt_svc(conn.host, 443))
    |> send_resp(200, "ok")
  end
end
