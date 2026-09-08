defmodule Gale.Stacks do
  @moduledoc """
  Stacks-specific HTTP/3 configurations for Gale.

  Provides pre-tuned `http3` options for common Stacks infrastructure:
  - API nodes
  - Wallet backends
  - sBTC relays

  ## Examples

      config :stacks_node, StacksNodeWeb.Endpoint,
        adapter: Gale.PhoenixAdapter,
        http3: Gale.Stacks.api_node_config()

  """

  @doc """
  Pre-tuned HTTP/3 config for Stacks API nodes.

  Optimized for high-concurrency `/v2/info` and `/v2/chain_info` endpoints.
  """
  def api_node_config do
    [
      port: 443,
      max_idle_timeout: 60_000,
      max_concurrent_bidi_streams: 200,
      max_concurrent_uni_streams: 10
    ]
  end

  @doc """
  Pre-tuned HTTP/3 config for wallet backends.

  Optimized for low-latency mobile wallet requests on cellular networks.
  """
  def wallet_backend_config do
    [
      port: 443,
      max_idle_timeout: 120_000,
      max_concurrent_bidi_streams: 100,
      max_concurrent_uni_streams: 10
    ]
  end

  @doc """
  Pre-tuned HTTP/3 config for sBTC relay HTTP servers.

  Optimized for high-throughput status and coordination endpoints.
  """
  def sbtc_relay_config do
    [
      port: 443,
      max_idle_timeout: 120_000,
      max_concurrent_bidi_streams: 200,
      max_concurrent_uni_streams: 10
    ]
  end

  @doc """
  Client-side HTTP/3 options for Stacks API requests.

  Use with `Gale.HTTP.get!/3`, `Gale.Req.get!/2`, etc.
  """
  def client_options do
    [
      http3: true,
      timeout: 30_000,
      recv_timeout: 30_000
    ]
  end
end
