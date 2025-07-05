defmodule ExESDB.Schema.SubscriptionRecord do
  @moduledoc false
  use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

  field(:subscription_group_name, 1,
    required: true,
    type: :string,
    json_name: "subscriptionGroupName"
  )

  field(:event_stream_id, 2, required: true, type: :string, json_name: "eventStreamId")
  field(:resolve_link_tos, 3, required: true, type: :bool, json_name: "resolveLinkTos")
  field(:start_from, 4, required: true, type: :int64, json_name: "startFrom")

  field(:message_timeout_milliseconds, 5,
    required: true,
    type: :int32,
    json_name: "messageTimeoutMilliseconds"
  )

  field(:record_statistics, 6, required: true, type: :bool, json_name: "recordStatistics")
  field(:live_buffer_size, 7, required: true, type: :int32, json_name: "liveBufferSize")
  field(:read_batch_size, 8, required: true, type: :int32, json_name: "readBatchSize")
  field(:buffer_size, 9, required: true, type: :int32, json_name: "bufferSize")
  field(:max_retry_count, 10, required: true, type: :int32, json_name: "maxRetryCount")
  field(:prefer_round_robin, 11, required: true, type: :bool, json_name: "preferRoundRobin")

  field(:checkpoint_after_time, 12,
    required: true,
    type: :int32,
    json_name: "checkpointAfterTime"
  )

  field(:checkpoint_max_count, 13, required: true, type: :int32, json_name: "checkpointMaxCount")
  field(:checkpoint_min_count, 14, required: true, type: :int32, json_name: "checkpointMinCount")
  field(:subscriber_max_count, 15, required: true, type: :int32, json_name: "subscriberMaxCount")

  field(:named_consumer_strategy, 16,
    optional: true,
    type: :string,
    json_name: "namedConsumerStrategy"
  )
end
