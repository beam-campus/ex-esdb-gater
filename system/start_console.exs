#!/usr/bin/env elixir

# ExESDB Gater Interactive Test Console Launcher
# Usage: elixir start_console.exs

IO.puts("Starting ExESDB Gater Interactive Test Console...")

# Add the lib directory to the code path
Code.append_path("lib")

# Start the console
ExESDBGater.Repl.Console.start()
