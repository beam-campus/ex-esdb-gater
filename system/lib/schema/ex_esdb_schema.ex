defmodule ExESDB.Schema do
  @moduledoc false
  defmodule OperationResult do
    @moduledoc false

    use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:success, 0)
    field(:prepare_timeout, 1)
    field(:commit_timeout, 2)
    field(:forward_timeout, 3)
    field(:wrong_expected_version, 4)
    field(:stream_deleted, 5)
    field(:invalid_transaction, 6)
    field(:access_denied, 7)
  end

  defmodule ReadEventCompleted.ReadEventResult do
    @moduledoc false

    use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:success, 0)
    field(:not_found, 1)
    field(:no_stream, 2)
    field(:stream_deleted, 3)
    field(:error, 4)
    field(:access_denied, 5)
  end

  defmodule ReadStreamEventsCompleted.ReadStreamResult do
    @moduledoc false

    use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:success, 0)
    field(:no_stream, 1)
    field(:stream_deleted, 2)
    field(:not_modified, 3)
    field(:error, 4)
    field(:access_denied, 5)
  end

  defmodule ReadAllEventsCompleted.ReadAllResult do
    @moduledoc false

    use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:success, 0)
    field(:not_modified, 1)
    field(:error, 2)
    field(:access_denied, 3)
  end

  defmodule UpdatePersistentSubscriptionCompleted.UpdatePersistentSubscriptionResult do
    @moduledoc false

    use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:success, 0)
    field(:does_not_exist, 1)
    field(:fail, 2)
    field(:access_denied, 3)
  end

  defmodule CreatePersistentSubscriptionCompleted.CreatePersistentSubscriptionResult do
    @moduledoc false

    use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:success, 0)
    field(:already_exists, 1)
    field(:fail, 2)
    field(:access_denied, 3)
  end

  defmodule DeletePersistentSubscriptionCompleted.DeletePersistentSubscriptionResult do
    @moduledoc false

    use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:success, 0)
    field(:does_not_exist, 1)
    field(:fail, 2)
    field(:access_denied, 3)
  end

  defmodule PersistentSubscriptionNakEvents.NakAction do
    @moduledoc false

    use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:unknown, 0)
    field(:park, 1)
    field(:retry, 2)
    field(:skip, 3)
    field(:stop, 4)
  end

  defmodule SubscriptionDropped.SubscriptionDropReason do
    @moduledoc false

    use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:unsubscribed, 0)
    field(:access_denied, 1)
    field(:not_found, 2)
    field(:persistent_subscription_deleted, 3)
    field(:subscriber_max_count_reached, 4)
  end

  defmodule NotHandled.NotHandledReason do
    @moduledoc false

    use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:not_ready, 0)
    field(:too_busy, 1)
    field(:not_master, 2)
  end

  defmodule ScavengeDatabaseCompleted.ScavengeResult do
    @moduledoc false

    use Protobuf, enum: true, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:success, 0)
    field(:in_progress, 1)
    field(:failed, 2)
  end

  defmodule ResolvedIndexedEvent do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:event, 1, required: true, type: EventRecord)
    field(:link, 2, optional: true, type: EventRecord)
  end

  defmodule ResolvedEvent do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:event, 1, required: true, type: EventRecord)
    field(:link, 2, optional: true, type: EventRecord)
    field(:commit_position, 3, required: true, type: :int64, json_name: "commitPosition")
    field(:prepare_position, 4, required: true, type: :int64, json_name: "preparePosition")
  end

  defmodule WriteEvents do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:event_stream_id, 1, required: true, type: :string, json_name: "eventStreamId")
    field(:expected_version, 2, required: true, type: :int64, json_name: "expectedVersion")
    field(:events, 3, repeated: true, type: NewEvent)
    field(:require_master, 4, required: true, type: :bool, json_name: "requireMaster")
  end

  defmodule WriteEventsCompleted do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:result, 1, required: true, type: OperationResult, enum: true)
    field(:message, 2, optional: true, type: :string)
    field(:first_event_number, 3, required: true, type: :int64, json_name: "firstEventNumber")
    field(:last_event_number, 4, required: true, type: :int64, json_name: "lastEventNumber")
    field(:prepare_position, 5, optional: true, type: :int64, json_name: "preparePosition")
    field(:commit_position, 6, optional: true, type: :int64, json_name: "commitPosition")
    field(:current_version, 7, optional: true, type: :int64, json_name: "currentVersion")
  end

  defmodule DeleteStream do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:event_stream_id, 1, required: true, type: :string, json_name: "eventStreamId")
    field(:expected_version, 2, required: true, type: :int64, json_name: "expectedVersion")
    field(:require_master, 3, required: true, type: :bool, json_name: "requireMaster")
    field(:hard_delete, 4, optional: true, type: :bool, json_name: "hardDelete")
  end

  defmodule DeleteStreamCompleted do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:result, 1, required: true, type: OperationResult, enum: true)
    field(:message, 2, optional: true, type: :string)
    field(:prepare_position, 3, optional: true, type: :int64, json_name: "preparePosition")
    field(:commit_position, 4, optional: true, type: :int64, json_name: "commitPosition")
  end

  defmodule TransactionStart do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:event_stream_id, 1, required: true, type: :string, json_name: "eventStreamId")
    field(:expected_version, 2, required: true, type: :int64, json_name: "expectedVersion")
    field(:require_master, 3, required: true, type: :bool, json_name: "requireMaster")
  end

  defmodule TransactionStartCompleted do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:transaction_id, 1, required: true, type: :int64, json_name: "transactionId")
    field(:result, 2, required: true, type: OperationResult, enum: true)
    field(:message, 3, optional: true, type: :string)
  end

  defmodule TransactionWrite do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:transaction_id, 1, required: true, type: :int64, json_name: "transactionId")
    field(:events, 2, repeated: true, type: NewEvent)
    field(:require_master, 3, required: true, type: :bool, json_name: "requireMaster")
  end

  defmodule TransactionWriteCompleted do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:transaction_id, 1, required: true, type: :int64, json_name: "transactionId")
    field(:result, 2, required: true, type: OperationResult, enum: true)
    field(:message, 3, optional: true, type: :string)
  end

  defmodule TransactionCommit do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:transaction_id, 1, required: true, type: :int64, json_name: "transactionId")
    field(:require_master, 2, required: true, type: :bool, json_name: "requireMaster")
  end

  defmodule TransactionCommitCompleted do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:transaction_id, 1, required: true, type: :int64, json_name: "transactionId")
    field(:result, 2, required: true, type: OperationResult, enum: true)
    field(:message, 3, optional: true, type: :string)
    field(:first_event_number, 4, required: true, type: :int64, json_name: "firstEventNumber")
    field(:last_event_number, 5, required: true, type: :int64, json_name: "lastEventNumber")
    field(:prepare_position, 6, optional: true, type: :int64, json_name: "preparePosition")
    field(:commit_position, 7, optional: true, type: :int64, json_name: "commitPosition")
  end

  defmodule ReadEvent do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:event_stream_id, 1, required: true, type: :string, json_name: "eventStreamId")
    field(:event_number, 2, required: true, type: :int64, json_name: "eventNumber")
    field(:resolve_link_tos, 3, required: true, type: :bool, json_name: "resolveLinkTos")
    field(:require_master, 4, required: true, type: :bool, json_name: "requireMaster")
  end

  defmodule ReadEventCompleted do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:result, 1, required: true, type: ReadEventCompleted.ReadEventResult, enum: true)
    field(:event, 2, required: true, type: ResolvedIndexedEvent)
    field(:io_error, 3, optional: true, type: :string, json_name: "ioError")
  end

  defmodule ReadStreamEvents do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:event_stream_id, 1, required: true, type: :string, json_name: "eventStreamId")
    field(:from_event_number, 2, required: true, type: :int64, json_name: "fromEventNumber")
    field(:max_count, 3, required: true, type: :int32, json_name: "maxCount")
    field(:resolve_link_tos, 4, required: true, type: :bool, json_name: "resolveLinkTos")
    field(:require_master, 5, required: true, type: :bool, json_name: "requireMaster")
  end

  defmodule ReadStreamEventsBackward do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:event_stream_id, 1, required: true, type: :string, json_name: "eventStreamId")
    field(:from_event_number, 2, required: true, type: :int64, json_name: "fromEventNumber")
    field(:max_count, 3, required: true, type: :int32, json_name: "maxCount")
    field(:resolve_link_tos, 4, required: true, type: :bool, json_name: "resolveLinkTos")
    field(:require_master, 5, required: true, type: :bool, json_name: "requireMaster")
  end

  defmodule ReadStreamEventsCompleted do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:events, 1, repeated: true, type: ResolvedIndexedEvent)

    field(:result, 2,
      required: true,
      type: ReadStreamEventsCompleted.ReadStreamResult,
      enum: true
    )

    field(:next_event_number, 3, required: true, type: :int64, json_name: "nextEventNumber")
    field(:last_event_number, 4, required: true, type: :int64, json_name: "lastEventNumber")
    field(:is_end_of_stream, 5, required: true, type: :bool, json_name: "isEndOfStream")
    field(:last_commit_position, 6, required: true, type: :int64, json_name: "lastCommitPosition")
    field(:io_error, 7, optional: true, type: :string, json_name: "ioError")
  end

  defmodule ReadAllEvents do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:commit_position, 1, required: true, type: :int64, json_name: "commitPosition")
    field(:prepare_position, 2, required: true, type: :int64, json_name: "preparePosition")
    field(:max_count, 3, required: true, type: :int32, json_name: "maxCount")
    field(:resolve_link_tos, 4, required: true, type: :bool, json_name: "resolveLinkTos")
    field(:require_master, 5, required: true, type: :bool, json_name: "requireMaster")
  end

  defmodule ReadAllEventsCompleted do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:commit_position, 1, required: true, type: :int64, json_name: "commitPosition")
    field(:prepare_position, 2, required: true, type: :int64, json_name: "preparePosition")
    field(:events, 3, repeated: true, type: ResolvedEvent)
    field(:next_commit_position, 4, required: true, type: :int64, json_name: "nextCommitPosition")

    field(:next_prepare_position, 5,
      required: true,
      type: :int64,
      json_name: "nextPreparePosition"
    )

    field(:result, 6,
      optional: true,
      type: ReadAllEventsCompleted.ReadAllResult,
      default: :success,
      enum: true
    )

    field(:io_error, 7, optional: true, type: :string, json_name: "ioError")
  end

  defmodule CreatePersistentSubscription do
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

    field(:checkpoint_max_count, 13,
      required: true,
      type: :int32,
      json_name: "checkpointMaxCount"
    )

    field(:checkpoint_min_count, 14,
      required: true,
      type: :int32,
      json_name: "checkpointMinCount"
    )

    field(:subscriber_max_count, 15,
      required: true,
      type: :int32,
      json_name: "subscriberMaxCount"
    )

    field(:named_consumer_strategy, 16,
      optional: true,
      type: :string,
      json_name: "namedConsumerStrategy"
    )
  end

  defmodule DeletePersistentSubscription do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:subscription_group_name, 1,
      required: true,
      type: :string,
      json_name: "subscriptionGroupName"
    )

    field(:event_stream_id, 2, required: true, type: :string, json_name: "eventStreamId")
  end

  defmodule UpdatePersistentSubscription do
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

    field(:checkpoint_max_count, 13,
      required: true,
      type: :int32,
      json_name: "checkpointMaxCount"
    )

    field(:checkpoint_min_count, 14,
      required: true,
      type: :int32,
      json_name: "checkpointMinCount"
    )

    field(:subscriber_max_count, 15,
      required: true,
      type: :int32,
      json_name: "subscriberMaxCount"
    )

    field(:named_consumer_strategy, 16,
      optional: true,
      type: :string,
      json_name: "namedConsumerStrategy"
    )
  end

  defmodule UpdatePersistentSubscriptionCompleted do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:result, 1,
      required: true,
      type: UpdatePersistentSubscriptionCompleted.UpdatePersistentSubscriptionResult,
      default: :success,
      enum: true
    )

    field(:reason, 2, optional: true, type: :string)
  end

  defmodule CreatePersistentSubscriptionCompleted do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:result, 1,
      required: true,
      type: CreatePersistentSubscriptionCompleted.CreatePersistentSubscriptionResult,
      default: :success,
      enum: true
    )

    field(:reason, 2, optional: true, type: :string)
  end

  defmodule DeletePersistentSubscriptionCompleted do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:result, 1,
      required: true,
      type: DeletePersistentSubscriptionCompleted.DeletePersistentSubscriptionResult,
      default: :success,
      enum: true
    )

    field(:reason, 2, optional: true, type: :string)
  end

  defmodule ConnectToPersistentSubscription do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:subscription_id, 1, required: true, type: :string, json_name: "subscriptionId")
    field(:event_stream_id, 2, required: true, type: :string, json_name: "eventStreamId")

    field(:allowed_in_flight_messages, 3,
      required: true,
      type: :int32,
      json_name: "allowedInFlightMessages"
    )
  end

  defmodule PersistentSubscriptionAckEvents do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:subscription_id, 1, required: true, type: :string, json_name: "subscriptionId")
    field(:processed_event_ids, 2, repeated: true, type: :bytes, json_name: "processedEventIds")
  end

  defmodule PersistentSubscriptionNakEvents do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:subscription_id, 1, required: true, type: :string, json_name: "subscriptionId")
    field(:processed_event_ids, 2, repeated: true, type: :bytes, json_name: "processedEventIds")
    field(:message, 3, optional: true, type: :string)

    field(:action, 4,
      required: true,
      type: PersistentSubscriptionNakEvents.NakAction,
      default: :unknown,
      enum: true
    )
  end

  defmodule PersistentSubscriptionConfirmation do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:last_commit_position, 1, required: true, type: :int64, json_name: "lastCommitPosition")
    field(:subscription_id, 2, required: true, type: :string, json_name: "subscriptionId")
    field(:last_event_number, 3, optional: true, type: :int64, json_name: "lastEventNumber")
  end

  defmodule PersistentSubscriptionStreamEventAppeared do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:event, 1, required: true, type: ResolvedIndexedEvent)
    field(:retryCount, 2, optional: true, type: :int32)
  end

  defmodule SubscribeToStream do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:event_stream_id, 1, required: true, type: :string, json_name: "eventStreamId")
    field(:resolve_link_tos, 2, required: true, type: :bool, json_name: "resolveLinkTos")
  end

  defmodule SubscriptionConfirmation do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:last_commit_position, 1, required: true, type: :int64, json_name: "lastCommitPosition")
    field(:last_event_number, 2, optional: true, type: :int64, json_name: "lastEventNumber")
  end

  defmodule StreamEventAppeared do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:event, 1, required: true, type: ResolvedEvent)
  end

  defmodule UnsubscribeFromStream do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2
  end

  defmodule SubscriptionDropped do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:reason, 1,
      optional: true,
      type: SubscriptionDropped.SubscriptionDropReason,
      default: :unsubscribed,
      enum: true
    )
  end

  defmodule NotHandled.MasterInfo do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:external_tcp_address, 1,
      required: true,
      type: :string,
      json_name: "externalTcpAddress"
    )

    field(:external_tcp_port, 2, required: true, type: :int32, json_name: "externalTcpPort")

    field(:external_http_address, 3,
      required: true,
      type: :string,
      json_name: "externalHttpAddress"
    )

    field(:external_http_port, 4, required: true, type: :int32, json_name: "externalHttpPort")

    field(:external_secure_tcp_address, 5,
      optional: true,
      type: :string,
      json_name: "externalSecureTcpAddress"
    )

    field(:external_secure_tcp_port, 6,
      optional: true,
      type: :int32,
      json_name: "externalSecureTcpPort"
    )
  end

  defmodule NotHandled do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:reason, 1, required: true, type: NotHandled.NotHandledReason, enum: true)
    field(:additional_info, 2, optional: true, type: :bytes, json_name: "additionalInfo")
  end

  defmodule ScavengeDatabase do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2
  end

  defmodule ScavengeDatabaseCompleted do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:result, 1, required: true, type: ScavengeDatabaseCompleted.ScavengeResult, enum: true)
    field(:error, 2, optional: true, type: :string)
    field(:total_time_ms, 3, required: true, type: :int32, json_name: "totalTimeMs")
    field(:total_space_saved, 4, required: true, type: :int64, json_name: "totalSpaceSaved")
  end

  defmodule IdentifyClient do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2

    field(:version, 1, required: true, type: :int32)
    field(:connection_name, 2, optional: true, type: :string, json_name: "connectionName")
  end

  defmodule ClientIdentified do
    @moduledoc false

    use Protobuf, protoc_gen_elixir_version: "0.14.1", syntax: :proto2
  end
end
