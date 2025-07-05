defmodule ExESDB.NewEvent do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

  field(:event_id, 1, required: true, type: :bytes, json_name: "eventId")
  field(:event_type, 2, required: true, type: :string, json_name: "eventType")
  field(:data_content_type, 3, required: true, type: :int32, json_name: "dataContentType")

  field(:metadata_content_type, 4,
    required: true,
    type: :int32,
    json_name: "metadataContentType"
  )

  field(:data, 5, required: true, type: :bytes)
  field(:metadata, 6, optional: true, type: :bytes)

end
