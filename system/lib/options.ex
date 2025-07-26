defmodule ExESDBGater.Options do
  @moduledoc """
    This module contains the options helper functions for ExESDBGater
  """

  def sys_env(key), do: System.get_env(key)
  def api_env, do: Application.get_env(:ex_esdb_gater, :api) || default_config()
  def api_env(key), do: Keyword.get(api_env(), key)

  @doc """
  Returns default configuration when no configuration is provided
  """
  def default_config do
    []
  end
end
