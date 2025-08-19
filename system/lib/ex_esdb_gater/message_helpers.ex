defmodule ExESDBGater.MessageHelpers do
  @moduledoc """
  Common utilities for ExESDBGater message creation, validation, and handling.

  This module provides consistent patterns for all message modules to ensure:
  - Proper node field tracking
  - Standardized timestamp handling
  - Message validation
  - Consistent defaults and patterns

  ## Node Field Guidelines

  All message structs should include a node-related field that tracks where the event originated:
  - `:node` - for general events originating on a node
  - `:originating_node` - for cluster events where distinction is needed from affected nodes
  - `:reporting_node` - for metrics/monitoring events where the reporter may differ from the source

  ## Usage

      # In message creation functions
      def my_message(arg1, arg2, opts \\ []) do
        %MyMessage{
          arg1: arg1,
          arg2: arg2,
          node: MessageHelpers.get_node(opts),
          timestamp: MessageHelpers.current_timestamp()
        }
      end

      # Validate message has required fields
      MessageHelpers.validate_message_fields(message, [:node, :timestamp])
  """

  @doc """
  Returns the current timestamp with millisecond precision in UTC.
  
  This ensures consistent timestamp formatting across all message types.
  """
  def current_timestamp do
    DateTime.utc_now() |> DateTime.truncate(:millisecond)
  end

  @doc """
  Gets the node value from options, defaulting to Node.self().
  
  ## Examples
  
      iex> MessageHelpers.get_node([])
      :"node@hostname"
      
      iex> MessageHelpers.get_node([node: :test_node])
      :test_node
  """
  def get_node(opts \\ []) do
    Keyword.get(opts, :node, Node.self())
  end

  @doc """
  Gets the originating_node value from options, defaulting to Node.self().
  
  Used for cluster membership and similar events where the originating node
  needs to be distinguished from affected nodes.
  """
  def get_originating_node(opts \\ []) do
    Keyword.get(opts, :originating_node, Node.self())
  end

  @doc """
  Gets the reporting_node value from options, defaulting to Node.self().
  
  Used for metrics and monitoring events where the reporting node
  may be different from the event source.
  """
  def get_reporting_node(opts \\ []) do
    Keyword.get(opts, :reporting_node, Node.self())
  end

  @doc """
  Validates that a message struct has all required fields.
  
  ## Parameters
  
  - `message` - The message struct to validate
  - `required_fields` - List of atoms representing required field names
  
  ## Examples
  
      iex> message = %MyMessage{node: :test, timestamp: DateTime.utc_now()}
      iex> MessageHelpers.validate_message_fields(message, [:node, :timestamp])
      {:ok, message}
      
      iex> message = %MyMessage{timestamp: DateTime.utc_now()}
      iex> MessageHelpers.validate_message_fields(message, [:node, :timestamp])
      {:error, {:missing_fields, [:node]}}
  """
  def validate_message_fields(message, required_fields) when is_list(required_fields) do
    message_map = if is_struct(message), do: Map.from_struct(message), else: message
    
    missing_fields = 
      required_fields
      |> Enum.filter(fn field ->
        case Map.get(message_map, field) do
          nil -> true
          _ -> false
        end
      end)
    
    case missing_fields do
      [] -> {:ok, message}
      fields -> {:error, {:missing_fields, fields}}
    end
  end

  @doc """
  Validates that all node-related fields in a message are atoms.
  
  ## Examples
  
      iex> message = %{node: :test_node, originating_node: :origin}
      iex> MessageHelpers.validate_node_fields(message)
      :ok
      
      iex> message = %{node: "invalid_node"}
      iex> MessageHelpers.validate_node_fields(message)
      {:error, {:invalid_node_fields, [:node]}}
  """
  def validate_node_fields(message) do
    node_fields = [:node, :originating_node, :reporting_node]
    message_map = if is_struct(message), do: Map.from_struct(message), else: message
    
    invalid_fields = 
      node_fields
      |> Enum.filter(fn field ->
        case Map.get(message_map, field) do
          nil -> false  # Missing fields are ok, they're optional
          value when is_atom(value) -> false  # Valid
          _ -> true  # Invalid (not an atom)
        end
      end)
    
    case invalid_fields do
      [] -> :ok
      fields -> {:error, {:invalid_node_fields, fields}}
    end
  end

  @doc """
  Extracts cluster context information for enhanced message tracking.
  
  This provides additional context that can be useful for debugging
  and monitoring in distributed environments.
  
  ## Returns
  
  A map containing:
  - `:node_name` - Current node name
  - `:connected_nodes` - List of connected nodes
  - `:cluster_size` - Number of nodes in cluster
  - `:node_type` - Derived node type (if determinable)
  """
  def cluster_context do
    connected_nodes = Node.list()
    
    %{
      node_name: Node.self(),
      connected_nodes: connected_nodes,
      cluster_size: length(connected_nodes) + 1,  # +1 for current node
      node_type: determine_node_type()
    }
  end

  @doc """
  Creates a unique identifier for messages that need tracking.
  
  Generates a short, URL-safe identifier that includes timestamp info
  for better traceability.
  """
  def generate_message_id(prefix \\ "msg") do
    timestamp = System.system_time(:microsecond)
    random = :crypto.strong_rand_bytes(4) |> Base.url_encode64(padding: false)
    "#{prefix}_#{timestamp}_#{random}"
  end

  @doc """
  Ensures consistent metadata structure across all messages.
  
  Merges provided metadata with standard cluster context information.
  
  ## Examples
  
      iex> MessageHelpers.enrich_metadata(%{custom: "value"})
      %{
        custom: "value",
        cluster_context: %{node_name: :node@host, cluster_size: 3, ...}
      }
  """
  def enrich_metadata(metadata \\ %{}) do
    standard_metadata = %{
      cluster_context: cluster_context()
    }
    
    Map.merge(standard_metadata, metadata)
  end

  # Private functions

  defp determine_node_type do
    # Heuristic to determine node type based on applications running
    applications = Application.loaded_applications() |> Enum.map(&elem(&1, 0))
    
    cond do
      :ex_esdb in applications -> :ex_esdb_node
      :ex_esdb_gater in applications -> :gater_node
      true -> :unknown
    end
  end

  @doc """
  Common validation for all message structs.
  
  This is a comprehensive validation that checks:
  - Required fields are present
  - Node fields are valid atoms
  - Timestamp is a valid DateTime
  
  ## Usage in message modules
  
      def validate(%MyMessage{} = message) do
        MessageHelpers.validate_common(message, [:field1, :field2])
      end
  """
  def validate_common(message, required_fields) do
    with {:ok, _} <- validate_message_fields(message, required_fields ++ [:timestamp]),
         :ok <- validate_node_fields(message),
         :ok <- validate_timestamp_field(message) do
      {:ok, message}
    end
  end

  defp validate_timestamp_field(message) do
    message_map = if is_struct(message), do: Map.from_struct(message), else: message
    
    case Map.get(message_map, :timestamp) do
      %DateTime{} -> :ok
      nil -> {:error, {:missing_fields, [:timestamp]}}
      _ -> {:error, {:invalid_timestamp, :not_datetime}}
    end
  end
end
