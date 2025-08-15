defmodule ExESDBGater.PubSubSystemUmbrellaTest do
  use ExUnit.Case, async: false
  
  alias ExESDBGater.PubSubSystem

  describe "PubSubSystem umbrella compatibility" do
    test "can start multiple PubSubSystem instances with same name" do
      # First instance should start normally
      assert {:ok, pid1} = PubSubSystem.start_link(name: :test_pubsub_system)
      
      # Second instance with same name should return existing pid, not fail
      assert {:ok, pid2} = PubSubSystem.start_link(name: :test_pubsub_system)
      
      # Should be the same pid (singleton behavior)
      assert pid1 == pid2
      
      # Clean up
      GenServer.stop(pid1)
    end
    
    test "multiple start attempts with default name behave correctly" do
      # First attempt should succeed
      assert {:ok, pid1} = PubSubSystem.start_link([])
      
      # Second attempt should return same pid (already_started handling)
      assert {:ok, pid2} = PubSubSystem.start_link([])
      
      # Should be the same pid
      assert pid1 == pid2
      
      # Clean up
      GenServer.stop(pid1)
    end
    
    test "simulates umbrella app scenario - multiple ExESDB systems sharing PubSub" do
      # Simulate what happens in an umbrella app with multiple ExESDB.System instances
      # Each tries to start PubSubSystem with the same registered name
      
      # First ExESDB.System starts PubSubSystem
      opts1 = [name: :ex_esdb_gater_pubsub, store_id: "store1"]
      assert {:ok, pid1} = PubSubSystem.start_link(opts1)
      
      # Second ExESDB.System tries to start PubSubSystem with same name
      # This should succeed and return the same pid (not fail)
      opts2 = [name: :ex_esdb_gater_pubsub, store_id: "store2"] 
      assert {:ok, pid2} = PubSubSystem.start_link(opts2)
      
      # Should be the same pid - shared PubSub infrastructure
      assert pid1 == pid2
      
      # Verify the PubSub instances are actually running
      for pubsub_name <- [:ex_esdb_events, :ex_esdb_system, :ex_esdb_logging] do
        assert is_pid(Process.whereis(pubsub_name))
        assert Process.alive?(Process.whereis(pubsub_name))
      end
      
      # Clean up
      GenServer.stop(pid1)
    end
  end
end
