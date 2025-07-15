defmodule ExESDBGater.EnVars do
  @moduledoc """
    This module contains the environment variables that are used by ExESDBGater
  """
  @doc """
    Returns the name of the pub/sub. default: `ex_esdb_pubsub`
  """
  def pub_sub, do: "EX_ESDB_PUB_SUB"
end
