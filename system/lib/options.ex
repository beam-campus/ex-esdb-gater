defmodule ExESDBGater.Options do
  @moduledoc """
    This module contains the options helper functions for ExESDBGater
  """
  alias ExESDBGater.EnVars, as: EnVars

  @pub_sub EnVars.pub_sub()

  def sys_env(key), do: System.get_env(key)
  def api_env, do: Application.get_env(:ex_esdb_gater, :api) || default_config()
  def api_env(key), do: Keyword.get(api_env(), key)

  @doc """
  Returns default configuration when no configuration is provided
  """
  def default_config do
    [
      pub_sub: :ex_esdb_pubsub
    ]
  end

  def pub_sub do
    # First check environment variable
    case sys_env(@pub_sub) do
      nil ->
        # Then check application config, default to :ex_esdb_pubsub
        case api_env(:pub_sub) do
          nil -> :ex_esdb_pubsub
          pub_sub -> pub_sub
        end
      pub_sub -> String.to_atom(pub_sub)
    end
  end
end
