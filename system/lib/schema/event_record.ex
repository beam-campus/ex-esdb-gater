defmodule ExESDB.Schema.EventRecord do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

  field(:event_stream_id, 1, required: true, type: :string, json_name: "eventStreamId")
  field(:event_number, 2, required: true, type: :int64, json_name: "eventNumber")
  field(:event_id, 3, required: true, type: :bytes, json_name: "eventId")
  field(:event_type, 4, required: true, type: :string, json_name: "eventType")
  field(:data_content_type, 5, required: true, type: :int32, json_name: "dataContentType")

  field(:metadata_content_type, 6,
    required: true,
    type: :int32,
    json_name: "metadataContentType"
  )

  field(:data, 7, required: true, type: :bytes)
  field(:metadata, 8, optional: true, type: :bytes)
  field(:created, 9, optional: true, type: :int64)
  field(:created_epoch, 10, optional: true, type: :int64, json_name: "createdEpoch")
end
