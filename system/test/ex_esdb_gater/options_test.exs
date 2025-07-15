defmodule ExESDBGater.OptionsTest do
  use ExUnit.Case, async: true

  alias ExESDBGater.Options

  describe "configuration resilience" do
    test "api_env returns default config when no config is provided" do
      # Temporarily clear the config
      original_config = Application.get_env(:ex_esdb_gater, :api)
      Application.put_env(:ex_esdb_gater, :api, nil)

      try do
        config = Options.api_env()
        assert is_list(config)
        assert config[:connect_to] == node()
        assert config[:pub_sub] == :ex_esdb_pubsub
      after
        # Restore original config
        Application.put_env(:ex_esdb_gater, :api, original_config)
      end
    end

    test "default_config returns proper default values" do
      config = Options.default_config()
      assert is_list(config)
      assert config[:connect_to] == node()
      assert config[:pub_sub] == :ex_esdb_pubsub
    end

    test "connect_to returns default when no config is provided" do
      original_config = Application.get_env(:ex_esdb_gater, :api)
      Application.put_env(:ex_esdb_gater, :api, nil)

      try do
        result = Options.connect_to()
        assert result == node()
      after
        Application.put_env(:ex_esdb_gater, :api, original_config)
      end
    end

    test "pub_sub returns default when no config is provided" do
      original_config = Application.get_env(:ex_esdb_gater, :api)
      Application.put_env(:ex_esdb_gater, :api, nil)

      try do
        result = Options.pub_sub()
        assert result == :ex_esdb_pubsub
      after
        Application.put_env(:ex_esdb_gater, :api, original_config)
      end
    end
  end

  describe "system initialization resilience" do
    test "System.init handles nil opts gracefully" do
      # This should not crash
      assert {:ok, children} = ExESDBGater.System.init(nil)
      assert is_list(children)
    end

    test "API.init handles nil opts gracefully" do
      # This should not crash
      assert {:ok, state} = ExESDBGater.API.init(nil)
      assert is_list(state)
      assert state[:swarm_registered] == false
    end
  end
end
