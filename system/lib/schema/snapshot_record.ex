defmodule ExESDB.Schema.SnapshotRecord do
  @moduledoc """
    A snapshot record
  """
  @type t :: %ExESDB.Schema.SnapshotRecord{
          source_uuid: String.t(),
          source_version: non_neg_integer,
          source_type: String.t(),
          data: binary,
          metadata: binary,
          created_at: DateTime.t(),
          created_epoch: non_neg_integer
        }

  defstruct [
    :source_uuid,
    :source_version,
    :source_type,
    :data,
    :metadata,
    :created_at,
    :created_epoch
  ]
end
