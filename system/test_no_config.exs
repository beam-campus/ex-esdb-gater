#!/usr/bin/env elixir

# Test script to verify that ExESDBGater can handle missing configuration gracefully

# Simulate the case where no configuration is provided by temporarily clearing the config
Application.put_env(:ex_esdb_gater, :api, nil)

# Test the Options module
IO.puts("Testing Options.api_env with no config...")
config = ExESDBGater.Options.api_env()
IO.puts("Result: #{inspect(config)}")

# Test individual option functions
IO.puts("\nTesting individual option functions...")
IO.puts("connect_to: #{inspect(ExESDBGater.Options.connect_to())}")
IO.puts("pub_sub: #{inspect(ExESDBGater.Options.pub_sub())}")

# Test that System.init can handle nil opts
IO.puts("\nTesting System.init with nil opts...")
try do
  # This should not crash
  _result = ExESDBGater.System.init(nil)
  IO.puts("System.init with nil opts: Success")
rescue
  e -> IO.puts("System.init with nil opts: Failed - #{inspect(e)}")
end

# Test that API.init can handle nil opts
IO.puts("\nTesting API.init with nil opts...")
try do
  # This should not crash
  _result = ExESDBGater.API.init(nil)
  IO.puts("API.init with nil opts: Success")
rescue
  e -> IO.puts("API.init with nil opts: Failed - #{inspect(e)}")
end

IO.puts("\nAll tests completed!")
