#! /bin/bash

# ExESDGater startup script with cluster support
set -e

echo "=== ExESDGater Cluster Startup ==="
echo "PATH=${PATH}"
echo "EX_ESDB_COOKIE=${EX_ESDB_COOKIE}"
echo "EX_ESDB_CLUSTER_SECRET=${EX_ESDB_CLUSTER_SECRET}"
echo "NODE_NAME=$(hostname)"

# # Set up Erlang cookie for cluster communication
# if [ -n "$EX_ESDB_COOKIE" ]; then
#   echo "Setting Erlang cookie from environment variable"
#   # Write to /root/.erlang.cookie (where Erlang distribution expects it)
#   echo "$EX_ESDB_COOKIE" > /root/.erlang.cookie
#   chmod 400 /root/.erlang.cookie
#   # Also write to current directory for compatibility
#   echo "$EX_ESDB_COOKIE" > ~/.erlang.cookie
#   chmod 400 ~/.erlang.cookie
# else
#   echo "Warning: EX_ESDB_COOKIE not set, using default"
# fi
#
# echo "Current cookie (from /root/.erlang.cookie):"
# cat /root/.erlang.cookie 2>/dev/null || echo "Cookie file not found"
# echo "Current cookie (from ~/.erlang.cookie):"
# cat ~/.erlang.cookie 2>/dev/null || echo "Cookie file not found"
#
# Check network connectivity for gossip multicast
echo "Network interface information:"
ip addr show

echo "Checking multicast support:"
ip maddr show 2>/dev/null || echo "Multicast info not available"

# Wait for network to be ready
echo "Waiting for network initialization..."
sleep 10

echo "Starting ExESDGater..."
exec /system/bin/ex_esdb_gater start
