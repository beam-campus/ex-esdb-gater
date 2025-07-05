#!/bin/bash

# ExESDB Gater Health Check with Cluster Awareness
echo "Checking if ex_esdb_gater is up on [$(hostname)]...for clique [$EX_ESDB_COOKIE]"

# Check if ExESDB Gater is registered with EPMD
if ! epmd -names | grep -q ex_esdb_gater; then
    echo "ERROR: ex_esdb_gater not registered with EPMD"
    exit 1
fi

# Check if application responds to RPC calls
if ! /system/bin/ex_esdb_gater rpc "IO.puts(:pong)" >/dev/null 2>&1; then
    echo "ERROR: ex_esdb_gater not responding to RPC calls"
    exit 1
fi

# Optional: Check cluster connectivity (only fail if cluster is expected)
if [ -n "$EX_ESDB_CLUSTER_SECRET" ]; then
    # In cluster mode, check if gossip port is listening
    if ! netstat -ln | grep -q :45892; then
        echo "WARNING: Gossip port 45892 not listening (cluster mode expected)"
        # Don't fail the health check for this, just warn
    fi
fi

echo "OK"
