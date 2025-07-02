defmodule ExESDBGater.Options do
  @moduledoc """
    This module contains the options helper functions for ExESDB
  """
  alias ExESDBGater.EnVars, as: EnVars

  @connect_to EnVars.connect_to()
  @pub_sub EnVars.pub_sub()

  def sys_env(key), do: System.get_env(key)
  def api_env, do: Application.get_env(:ex_esdb_gater, :api)
  def api_env(key), do: Keyword.get(api_env(), key)

  def connect_to do
    case sys_env(@connect_to) do
      nil -> api_env(:connect_to) || node()
      connect_to -> String.to_atom(connect_to)
    end
  end

  def pub_sub do
    case sys_env(@pub_sub) do
      nil -> api_env(:pub_sub) || :ex_esdb_pubsub
      pub_sub -> String.to_atom(pub_sub)
    end
  end
end
