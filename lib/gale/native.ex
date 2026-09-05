defmodule Gale.Native do
  @moduledoc "Zig NIF entry points. Prefer `Gale.qpack_encode/1` and friends."

  @on_load :load_nif

  def load_nif do
    path =
      case :code.priv_dir(:gale) do
        {:error, _} ->
          Path.expand("../../priv/gale_nif", __DIR__)

        dir ->
          Path.join(dir, "gale_nif")
      end

    :erlang.load_nif(String.to_charlist(path), 0)
  rescue
    _ -> :ok
  end

  def qpack_encode(_headers), do: :erlang.nif_error(:nif_not_loaded)
  def qpack_decode(_bin), do: :erlang.nif_error(:nif_not_loaded)
  def h3_frame_encode(_kind, _payload), do: :erlang.nif_error(:nif_not_loaded)
  def h3_frame_decode(_bin), do: :erlang.nif_error(:nif_not_loaded)
  def quic_varint_encode(_n), do: :erlang.nif_error(:nif_not_loaded)
  def quic_varint_decode(_bin), do: :erlang.nif_error(:nif_not_loaded)
  def quic_parse_long_header(_bin), do: :erlang.nif_error(:nif_not_loaded)
  def blake3(_bin), do: :erlang.nif_error(:nif_not_loaded)
  def xxh3(_bin), do: :erlang.nif_error(:nif_not_loaded)
end
