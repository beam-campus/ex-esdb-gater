defmodule ExESDB.StoreManagerTest do
  use ExUnit.Case, async: false
  
  alias ExESDB.StoreManager
  
  describe "Dynamic Store Management" do
    
    test "can create a new store dynamically" do
      store_id = :test_store_#{:rand.uniform(10000)}
      config = [data_dir: "/tmp/test_stores", timeout: 5000]
      
      # Create the store
      assert {:ok, ^store_id} = StoreManager.create_store(store_id, config)
      
      # Verify it's in the list
      stores = StoreManager.list_stores()
      assert Map.has_key?(stores, store_id)
      
      # Check its status
      assert {:ok, :running} = StoreManager.get_store_status(store_id)
      
      # Check its config
      assert {:ok, stored_config} = StoreManager.get_store_config(store_id)
      assert Keyword.get(stored_config, :store_id) == store_id
      
      # Clean up
      assert :ok = StoreManager.remove_store(store_id)
    end
    
    test "cannot create store with duplicate id" do
      store_id = :duplicate_test_store
      config = [data_dir: "/tmp/test_stores", timeout: 5000]
      
      # Create the store first time
      assert {:ok, ^store_id} = StoreManager.create_store(store_id, config)
      
      # Try to create with same ID
      assert {:error, :already_exists} = StoreManager.create_store(store_id, config)
      
      # Clean up
      assert :ok = StoreManager.remove_store(store_id)
    end
    
    test "can remove a store" do
      store_id = :remove_test_store
      config = [data_dir: "/tmp/test_stores", timeout: 5000]
      
      # Create the store
      assert {:ok, ^store_id} = StoreManager.create_store(store_id, config)
      
      # Remove it
      assert :ok = StoreManager.remove_store(store_id)
      
      # Verify it's gone
      assert {:error, :not_found} = StoreManager.get_store_status(store_id)
    end
    
    test "removing non-existent store returns error" do
      assert {:error, :not_found} = StoreManager.remove_store(:non_existent_store)
    end
    
    test "can list all stores" do
      store_ids = [:list_test_1, :list_test_2]
      config = [data_dir: "/tmp/test_stores", timeout: 5000]
      
      # Create multiple stores
      for store_id <- store_ids do
        assert {:ok, ^store_id} = StoreManager.create_store(store_id, config)
      end
      
      # List stores
      stores = StoreManager.list_stores()
      
      # Verify both are present
      for store_id <- store_ids do
        assert Map.has_key?(stores, store_id)
        assert stores[store_id].status == :running
      end
      
      # Clean up
      for store_id <- store_ids do
        assert :ok = StoreManager.remove_store(store_id)
      end
    end
  end
end
