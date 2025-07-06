# Dynamic Store Creation Demo
# This script demonstrates how to create multiple stores dynamically using the ExESDBGater.API

IO.puts("=== ExESDB Dynamic Store Creation Demo ===\n")

# For this demo, we assume ExESDB and ExESDBGater are running in the cluster
# In a real scenario, you would call these functions from your application

# Example 1: Create a new store for user data
IO.puts("1. Creating a user data store...")
:ok = ExESDBGater.API.create_store(:user_data_store, [timeout: 15_000])
IO.puts("   ✓ User data store creation initiated")

# Example 2: Create a store for analytics
IO.puts("\n2. Creating an analytics store...")
:ok = ExESDBGater.API.create_store(:analytics_store, [timeout: 10_000])
IO.puts("   ✓ Analytics store creation initiated")

# Example 3: Create a store for audit logs
IO.puts("\n3. Creating an audit logs store...")
:ok = ExESDBGater.API.create_store(:audit_logs_store, [])
IO.puts("   ✓ Audit logs store creation initiated")

# Wait a moment for stores to be created
Process.sleep(2_000)

# Example 4: List all stores
IO.puts("\n4. Listing all stores...")
case ExESDBGater.API.list_stores() do
  {:ok, stores} ->
    IO.puts("   Found #{map_size(stores)} stores:")
    for {store_id, info} <- stores do
      IO.puts("   - #{store_id}: #{info.status}")
    end
  {:error, reason} ->
    IO.puts("   Error listing stores: #{inspect(reason)}")
end

# Example 5: Check status of a specific store
IO.puts("\n5. Checking status of user_data_store...")
case ExESDBGater.API.get_store_status(:user_data_store) do
  {:ok, status} ->
    IO.puts("   Status: #{status}")
  {:error, reason} ->
    IO.puts("   Error: #{inspect(reason)}")
end

# Example 6: Get configuration of a store
IO.puts("\n6. Getting configuration of analytics_store...")
case ExESDBGater.API.get_store_config(:analytics_store) do
  {:ok, config} ->
    IO.puts("   Configuration: #{inspect(config, pretty: true)}")
  {:error, reason} ->
    IO.puts("   Error: #{inspect(reason)}")
end

# Example 7: Use a store for event operations
IO.puts("\n7. Using the user_data_store for events...")
events = [
  %{
    event_type: "user_registered",
    data: %{user_id: "123", email: "user@example.com"},
    metadata: %{timestamp: DateTime.utc_now()}
  }
]

case ExESDBGater.API.append_events(:user_data_store, "user-123", events) do
  {:ok, new_version} ->
    IO.puts("   ✓ Events appended successfully, new version: #{new_version}")
  {:error, reason} ->
    IO.puts("   Error appending events: #{inspect(reason)}")
end

# Example 8: Read events from the store
IO.puts("\n8. Reading events from user_data_store...")
case ExESDBGater.API.get_events(:user_data_store, "user-123", 0, 10, :forward) do
  {:ok, events} ->
    IO.puts("   ✓ Retrieved #{length(events)} events")
    for event <- events do
      IO.puts("     - #{event.event_type} at #{event.created_at}")
    end
  {:error, reason} ->
    IO.puts("   Error reading events: #{inspect(reason)}")
end

# Example 9: Clean up - remove some stores
IO.puts("\n9. Cleaning up - removing test stores...")
:ok = ExESDBGater.API.remove_store(:analytics_store)
IO.puts("   ✓ Analytics store removal initiated")

:ok = ExESDBGater.API.remove_store(:audit_logs_store)
IO.puts("   ✓ Audit logs store removal initiated")

# Wait for cleanup
Process.sleep(1_000)

# Final status
IO.puts("\n10. Final store list:")
case ExESDBGater.API.list_stores() do
  {:ok, stores} ->
    IO.puts("    Remaining stores: #{map_size(stores)}")
    for {store_id, info} <- stores do
      IO.puts("    - #{store_id}: #{info.status}")
    end
  {:error, reason} ->
    IO.puts("    Error listing stores: #{inspect(reason)}")
end

IO.puts("\n=== Demo Complete ===")
IO.puts("\nKey Benefits of Dynamic Store Creation:")
IO.puts("• Create stores on-demand for different domains/tenants")
IO.puts("• Isolate data by creating separate stores per customer")
IO.puts("• Scale horizontally by distributing stores across the cluster")
IO.puts("• Manage store lifecycle independently")
IO.puts("• Configure each store with different parameters")
