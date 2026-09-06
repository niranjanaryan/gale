defmodule Gale.Storage.CID do
  @moduledoc """
  S5-style blob CID: `0x5b 0x82 0x1e` + BLAKE3-256 + unsigned LEB128 size.
  """
  defstruct [:hash, :size, algo: :blake3]

  def encode(%__MODULE__{hash: hash, size: size}) when byte_size(hash) == 32 do
    <<0x5B, 0x82, 0x1E, hash::binary, leb128(size || 0)::binary>>
  end

  def decode(<<0x5B, 0x82, 0x1E, hash::binary-size(32), rest::binary>>) do
    {size, _} = unleb128(rest)
    {:ok, %__MODULE__{hash: hash, size: size, algo: :blake3}}
  end

  def decode(_), do: {:error, :bad_cid}

  def hex(%__MODULE__{hash: hash}), do: Base.encode16(hash, case: :lower)

  defp leb128(n) when n < 128, do: <<n>>
  defp leb128(n), do: <<rem(n, 128) + 128::8, leb128(div(n, 128))::binary>>

  defp unleb128(<<b, rest::binary>>) when b < 128, do: {b, rest}

  defp unleb128(<<b, rest::binary>>) do
    {hi, rest2} = unleb128(rest)
    {b - 128 + hi * 128, rest2}
  end

  defp unleb128(<<>>), do: {0, <<>>}
end
