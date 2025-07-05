defmodule ExESDB.Schema.SimpleSubscriptionRecord do
  @moduledoc false
  defstruct [
    :type,
    :selector,
    :subscription_name,
    :start_from,
    :subscriber
  ]
end
