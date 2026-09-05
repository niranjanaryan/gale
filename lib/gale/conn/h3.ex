defmodule Gale.Conn.H3 do
  @moduledoc false
  @behaviour Plug.Conn.Adapter

  defstruct [:quic, :stream_id, :body, :peer]

  @impl true
  def send_resp(%__MODULE__{} = s, status, headers, body) do
    send(self(), {:plug_conn, :sent})
    hdrs = Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)
    :ok = :quic_h3.send_response(s.quic, s.stream_id, status, hdrs)
    body_bin = IO.iodata_to_binary(body)
    :ok = :quic_h3.send_data(s.quic, s.stream_id, body_bin, true)
    {:ok, nil, s}
  rescue
    _ -> {:ok, nil, s}
  end

  @impl true
  def send_file(s, status, headers, path, offset, length) do
    {:ok, %{size: size}} = File.stat(path)
    len = if length == :all, do: size - offset, else: length
    {:ok, fd} = :file.open(String.to_charlist(path), [:read, :raw, :binary])
    {:ok, slice} = :file.pread(fd, offset, len)
    :file.close(fd)
    send_resp(s, status, headers, slice)
  end

  @impl true
  def send_chunked(s, status, headers) do
    hdrs = Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)
    :ok = :quic_h3.send_response(s.quic, s.stream_id, status, hdrs)
    send(self(), {:plug_conn, :sent})
    {:ok, nil, s}
  end

  @impl true
  def chunk(s, body) do
    :ok = :quic_h3.send_data(s.quic, s.stream_id, IO.iodata_to_binary(body), false)
    {:ok, nil, s}
  end

  @impl true
  def read_req_body(%__MODULE__{body: body} = s, _opts) do
    {:ok, body || "", %{s | body: ""}}
  end

  @impl true
  def inform(_s, _status, _headers), do: {:error, :not_supported}

  @impl true
  def upgrade(_s, _proto, _opts), do: {:error, :not_supported}

  @impl true
  def push(_s, _path, _headers), do: {:error, :not_supported}

  @impl true
  def get_peer_data(%__MODULE__{peer: peer}) do
    peer || %{address: {127, 0, 0, 1}, port: 0, ssl_cert: nil}
  end

  @impl true
  def get_http_protocol(_s), do: :"HTTP/3"
end
