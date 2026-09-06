defmodule Gale.Storage.S3 do
  @moduledoc """
  S3 PUT/GET with optional AWS SigV4. BLAKE3 stored as `x-amz-meta-blake3`.

  Object key defaults to the hex BLAKE3 digest (content-addressed overlay
  on location-addressed S3).
  """

  alias Gale.Storage.CID

  def put(data, opts) when is_binary(data) do
    cid = Keyword.get_lazy(opts, :cid, fn -> Gale.Storage.S5.cid(data) end)
    key = Keyword.get(opts, :key, CID.hex(cid))
    bucket = Keyword.fetch!(opts, :bucket)
    host = Keyword.get(opts, :host) || "#{bucket}.s3.amazonaws.com"
    region = Keyword.get(opts, :region, "us-east-1")
    scheme = Keyword.get(opts, :scheme, "https")
    url = "#{scheme}://#{host}/#{uri_encode(key)}"
    blake_hex = CID.hex(cid)

    headers0 = [
      {"host", host},
      {"x-amz-meta-blake3", blake_hex},
      {"x-amz-meta-xxh3", Integer.to_string(Gale.xxh3(data))},
      {"content-type", Keyword.get(opts, :content_type, "application/octet-stream")}
    ]

    headers = maybe_sign(opts, :put, "/" <> key, headers0, data, region, host)
    req = {String.to_charlist(url), encode_headers(headers), ~c"application/octet-stream", data}

    case :httpc.request(:put, req, [timeout: Keyword.get(opts, :timeout, 30_000)], []) do
      {:ok, {{_, code, _}, _, _}} when code in 200..299 -> {:ok, cid}
      {:ok, {{_, code, _}, _, body}} -> {:error, {code, body}}
      {:error, reason} -> {:error, reason}
    end
  end

  def get(%CID{} = cid, opts) do
    key = Keyword.get(opts, :key, CID.hex(cid))
    bucket = Keyword.fetch!(opts, :bucket)
    host = Keyword.get(opts, :host) || "#{bucket}.s3.amazonaws.com"
    region = Keyword.get(opts, :region, "us-east-1")
    scheme = Keyword.get(opts, :scheme, "https")
    url = "#{scheme}://#{host}/#{uri_encode(key)}"
    headers = maybe_sign(opts, :get, "/" <> key, [{"host", host}], "", region, host)

    case :httpc.request(
           :get,
           {String.to_charlist(url), encode_headers(headers)},
           [timeout: Keyword.get(opts, :timeout, 30_000)],
           []
         ) do
      {:ok, {{_, 200, _}, _, body}} ->
        Gale.Storage.verify(IO.iodata_to_binary(body), cid)

      {:ok, {{_, code, _}, _, body}} ->
        {:error, {code, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_sign(opts, method, path, headers, payload, region, host) do
    if Keyword.get(opts, :unsigned, false) do
      headers
    else
      case {Keyword.get(opts, :access_key_id), Keyword.get(opts, :secret_access_key)} do
        {ak, sk} when is_binary(ak) and is_binary(sk) ->
          sign(
            method,
            path,
            headers,
            payload,
            region,
            host,
            ak,
            sk,
            Keyword.get(opts, :session_token)
          )

        _ ->
          headers
      end
    end
  end

  defp sign(method, path, headers, payload, region, _host, ak, sk, token) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    amz_date = Calendar.strftime(now, "%Y%m%dT%H%M%SZ")
    datestamp = Calendar.strftime(now, "%Y%m%d")
    payload_hash = sha256_hex(payload)

    headers =
      headers
      |> put_hdr("x-amz-date", amz_date)
      |> put_hdr("x-amz-content-sha256", payload_hash)
      |> then(fn h -> if token, do: put_hdr(h, "x-amz-security-token", token), else: h end)

    signed_names =
      headers
      |> Enum.map(fn {k, _} -> String.downcase(k) end)
      |> Enum.sort()
      |> Enum.uniq()

    canonical_headers =
      signed_names
      |> Enum.map(fn n -> n <> ":" <> hdr_value(headers, n) <> "\n" end)
      |> IO.iodata_to_binary()

    signed_headers = Enum.join(signed_names, ";")
    method_s = method |> Atom.to_string() |> String.upcase()

    canonical =
      method_s <>
        "\n" <>
        path <> "\n\n" <> canonical_headers <> "\n" <> signed_headers <> "\n" <> payload_hash

    scope = datestamp <> "/" <> region <> "/s3/aws4_request"

    string_to_sign =
      "AWS4-HMAC-SHA256\n" <> amz_date <> "\n" <> scope <> "\n" <> sha256_hex(canonical)

    signing_key = aws_signing_key(sk, datestamp, region, "s3")
    sig = hmac_hex(signing_key, string_to_sign)

    auth =
      "AWS4-HMAC-SHA256 Credential=#{ak}/#{scope}, SignedHeaders=#{signed_headers}, Signature=#{sig}"

    put_hdr(headers, "authorization", auth)
  end

  defp aws_signing_key(secret, date, region, service) do
    ("AWS4" <> secret)
    |> hmac(date)
    |> hmac(region)
    |> hmac(service)
    |> hmac("aws4_request")
  end

  defp hmac(key, data), do: :crypto.mac(:hmac, :sha256, key, data)
  defp hmac_hex(key, data), do: Base.encode16(hmac(key, data), case: :lower)
  defp sha256_hex(data), do: Base.encode16(:crypto.hash(:sha256, data), case: :lower)

  defp put_hdr(headers, k, v),
    do: [
      {k, v} | Enum.reject(headers, fn {hk, _} -> String.downcase(hk) == String.downcase(k) end)
    ]

  defp hdr_value(headers, name) do
    {_, v} = Enum.find(headers, fn {k, _} -> String.downcase(k) == name end)
    v
  end

  defp encode_headers(headers) do
    Enum.map(headers, fn {k, v} -> {String.to_charlist(k), String.to_charlist(v)} end)
  end

  defp uri_encode(key) do
    key |> String.split("/") |> Enum.map(&URI.encode_www_form/1) |> Enum.join("/")
  end
end
