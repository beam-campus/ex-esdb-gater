# LibCluster Discovery Hanging Fixes

This document summarizes the critical fixes implemented to resolve LibCluster discovery hanging issues between ExESDB and ExESDBGater.

## Root Cause Analysis

### Primary Issues Identified:
1. **Conflicting LibCluster Configurations**: Different multicast addresses and topology settings
2. **Startup Race Conditions**: Both applications trying to start LibCluster simultaneously
3. **Blocking Swarm Registration**: Immediate Swarm registration causing circular dependencies
4. **Aggressive RPC Timeouts**: Long RPC timeouts causing hanging behavior

## Implemented Solutions

### 1. Unified LibCluster Configuration (`SharedClusterConfig`)
**File**: `lib/ex_esdb_gater/shared_cluster_config.ex`

- **Centralized Configuration**: Single source of truth for all cluster settings
- **Environment Variable Support**: Configurable via environment variables
- **Validation**: Built-in configuration validation and warnings
- **Consistent Multicast**: Uses `239.255.0.1` instead of conflicting addresses

**Benefits**:
- Eliminates configuration conflicts
- Ensures both applications use identical cluster topology
- Prevents discovery protocol confusion

### 2. Enhanced LibClusterHelper (`LibClusterHelper`)
**File**: `lib/ex_esdb_gater/lib_cluster_helper.ex`

**Improvements**:
- **Startup Delay**: 100ms delay to prevent race conditions
- **Timeout Protection**: 5-second timeout for status checks
- **Unified Topology**: Always uses `SharedClusterConfig.topology()`
- **Better Error Handling**: Graceful fallback on failures

**Benefits**:
- Prevents startup race conditions
- Protects against hanging during status checks
- Provides consistent behavior across applications

### 3. Graceful Swarm Registration (`ExESDBGater.API`)
**File**: `lib/ex_esdb_gater/api.ex`

**Changes**:
- **Delayed Registration**: 2-second delay before Swarm registration
- **Retry Logic**: Automatic retry every 5 seconds on failure
- **State Tracking**: Tracks registration status
- **Better Logging**: Clear status messages

**Benefits**:
- Prevents circular dependencies with LibCluster
- Allows LibCluster to stabilize before Swarm operations
- Provides resilience against temporary Swarm unavailability

### 4. Improved RPC Handling (`ClusterMonitor`)
**File**: `lib/ex_esdb_gater/cluster_monitor.ex`

**Enhancements**:
- **Shorter Timeouts**: Reduced from 5s to 2s
- **Better Error Handling**: Specific handling for timeout and nodedown
- **Detailed Logging**: More informative debug messages
- **Graceful Degradation**: Continues operation on RPC failures

**Benefits**:
- Prevents hanging on slow RPC calls
- Provides better visibility into cluster state
- Reduces blocking behavior during node detection

### 5. Updated Runtime Configurations

**Files**:
- `config/runtime.exs` (both ExESDB and ExESDBGater)

**Changes**:
- **Unified Config Reference**: Both use `SharedClusterConfig.topology()`
- **Removed Conflicts**: Eliminated different multicast addresses
- **Simplified Setup**: Single configuration source

## Environment Variables

The unified configuration supports these environment variables:

```bash
# Cluster networking
EX_ESDB_CLUSTER_PORT=45892                    # Default: 45892
EX_ESDB_CLUSTER_INTERFACE=0.0.0.0            # Default: 0.0.0.0
EX_ESDB_GOSSIP_MULTICAST_ADDR=239.255.0.1    # Default: 239.255.0.1
EX_ESDB_CLUSTER_SECRET=your_secret_here       # Default: dev_cluster_secret

# Container environment detection
CONTAINER_ENV=true                            # Enables container-specific warnings
```

## Testing the Fixes

### 1. Configuration Validation
```elixir
# In IEx console
ExESDBGater.SharedClusterConfig.validate_config()
```

### 2. Check Cluster Topology
```elixir
# Verify both apps use same config
ExESDBGater.SharedClusterConfig.topology()
```

### 3. Monitor Startup Logs
Look for these log messages:
- `"Starting SharedLibCluster with unified config"`
- `"SharedLibCluster already running, skipping"`
- `"Successfully registered with Swarm"`

## Expected Behavior

### Successful Startup Sequence:
1. **ExESDB starts first** (due to startup order)
2. **LibClusterHelper** adds 100ms delay, then starts `SharedLibCluster`
3. **ExESDBGater starts** and detects existing `SharedLibCluster`
4. **Both applications** proceed with their own components
5. **API registration** happens after 2-second delay
6. **Cluster discovery** proceeds with unified configuration

### Log Patterns:
```
[info] Starting SharedLibCluster with unified config
[info] SharedLibCluster already running, skipping  
[info] Successfully registered with Swarm
[debug] Confirmed node@host is running ExESDB
```

## Monitoring and Troubleshooting

### Key Metrics to Monitor:
- LibCluster startup time
- Swarm registration success rate
- RPC call timeouts
- Node discovery latency

### Common Issues:
1. **Port Conflicts**: Check `EX_ESDB_CLUSTER_PORT` environment variable
2. **Network Issues**: Verify multicast is working in your environment
3. **Container Networking**: Set `CONTAINER_ENV=true` for container deployments

## Future Improvements

1. **Dynamic Port Allocation**: Automatically find available ports
2. **Health Checks**: Built-in cluster health monitoring
3. **Metrics**: Expose LibCluster metrics for monitoring
4. **Alternative Strategies**: Support for other clustering strategies beyond Gossip

## Files Modified

### ExESDBGater:
- `lib/ex_esdb_gater/shared_cluster_config.ex` (new)
- `lib/ex_esdb_gater/lib_cluster_helper.ex` (enhanced)
- `lib/ex_esdb_gater/api.ex` (graceful Swarm registration)
- `lib/ex_esdb_gater/cluster_monitor.ex` (improved RPC handling)
- `config/runtime.exs` (unified config reference)

### ExESDB:
- `lib/ex_esdb/system.ex` (use unified helper)
- `config/runtime.exs` (unified config reference)

These changes should eliminate the LibCluster discovery hanging issues and provide a much more stable and predictable clustering experience.
