# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

ExESDB Gater is a high-availability gateway service that provides secure, load-balanced access to ExESDB event store clusters. It acts as a proxy layer between client applications and ExESDB nodes, offering simplified API access and automatic cluster discovery using LibCluster.

The project consists of two main directories:
- **Root directory**: Project-level documentation and Docker configuration
- **system/**: The main Elixir application code

## Architecture

### Core Components

**ExESDBGater.Application**: Main application supervisor that starts the gateway system
- Starts `ExESDBGater.System` as the main supervisor

**ExESDBGater.System**: Primary supervisor managing all gateway services
- `LibClusterHelper`: Manages LibCluster for automatic cluster discovery  
- `ExESDBGater.ClusterMonitor`: Monitors cluster node connections and health
- `ExESDBGater.PubSubSystem`: Manages multiple dedicated PubSub instances
- `ExESDBGater.API`: Main API interface providing event store operations

**ExESDBGater.API**: Core gateway that proxies requests to distributed GaterWorkers
- Uses Swarm for distributed process management across cluster nodes
- Implements load balancing with random worker selection
- Provides comprehensive event store operations (streams, events, subscriptions, snapshots)

### Cluster Architecture

The system uses a distributed architecture where:
- **GaterWorkers** run on each ExESDB node, providing direct event store access
- **GaterAPI** instances route client requests to appropriate workers across the cluster  
- **LibCluster** with Gossip strategy enables automatic node discovery via UDP multicast
- **Swarm** manages distributed worker coordination and fault tolerance

### Multi-Instance PubSub Architecture (ADR-001)

The system implements 10 dedicated PubSub instances for event separation:
- `:ex_esdb_events` - Core business events and domain data
- `:ex_esdb_system` - General system-level events
- `:ex_esdb_logging` - Log aggregation and distribution
- `:ex_esdb_health` - Health monitoring and status events
- `:ex_esdb_metrics` - Performance metrics and statistics
- `:ex_esdb_security` - Security events and threat detection
- `:ex_esdb_audit` - Audit trail for compliance
- `:ex_esdb_alerts` - Critical system alerts
- `:ex_esdb_diagnostics` - Deep diagnostic information
- `:ex_esdb_lifecycle` - Process lifecycle events

This architecture provides fault isolation, independent scaling, and selective subscription capabilities.

## Common Commands

### Development Commands

```bash
# Navigate to main application directory
cd system

# Install dependencies
mix deps.get

# Compile project
mix compile

# Run tests
mix test

# Run single test file
mix test test/path/to/specific_test.exs

# Start interactive development session
iex -S mix

# Generate documentation
mix docs

# Run static code analysis
mix credo

# Run Dialyzer for type checking
mix dialyzer

# Format code
mix format

# Check formatting
mix format --check-formatted
```

### Release and Deployment

```bash
# Build release
cd system
MIX_ENV=prod mix release

# Create Docker image (from project root)
docker build -f system/Dockerfile -t ex_esdb_gater:latest system/

# Publish to Hex
cd system
./pub2hex.sh
```

### Health and Monitoring

```bash
# Check gateway health (in Docker)
docker exec ex-esdb-gater ./check-ex-esdb-gater.sh

# Test cluster connectivity
docker exec ex-esdb-gater ./test-cluster-connectivity.sh

# View connected nodes
docker exec ex-esdb-gater /opt/ex_esdb_gater/bin/ex_esdb_gater rpc "Node.list()."
```

### Docker Development Environment

```bash
# From project root, start development environment
cd dev-env
./gater-manager.sh  # Interactive menu for managing services

# Manual Docker Compose start
docker-compose \
  -f ex-esdb-network.yaml \
  -f ex-esdb-gater.yaml \
  -f ex-esdb-gater-override.yaml \
  --profile gater \
  -p gater \
  up -d
```

## Configuration

### Essential Environment Variables

- `EX_ESDB_CLUSTER_SECRET`: Shared secret for cluster authentication (required)
- `EX_ESDB_COOKIE`: Erlang distribution cookie (required)  
- `RELEASE_COOKIE`: Release-specific distribution cookie
- `EX_ESDB_PUB_SUB`: PubSub process name (default: `:ex_esdb_pubsub`)

### LibCluster Configuration

Located in `config/runtime.exs`, uses `ExESDBGater.SharedClusterConfig.topology()` for consistency with ExESDB cluster configuration. Uses Gossip strategy with UDP multicast on port 45892.

## Key Dependencies

- **libcluster**: Automatic cluster discovery and formation
- **swarm**: Distributed process management and coordination
- **phoenix_pubsub**: Event distribution across multiple dedicated instances
- **bc_utils**: Beam Campus utilities for logging and common functionality
- **protobuf**: Protocol buffer support for event serialization
- **uuidv7**: UUID generation for distributed systems

## Testing

Tests are located in the `test/` directory with comprehensive coverage of:
- Gateway API functionality (`gateway_api_test.exs`)
- PubSub system and multiple instances (`pubsub_*_test.exs`)  
- Message handling for all event types (`messages/*_test.exs`)
- Configuration and options (`options_test.exs`)

Run tests with `mix test` from the `system/` directory.

## Code Style and Architecture

- Follows idiomatic Elixir patterns with pattern matching over case statements
- Uses multiple function clauses and guards instead of conditional logic where appropriate
- Avoids `try..rescue` constructs in favor of pattern matching on return tuples
- Leverages LibCluster instead of seed_nodes mechanism for cluster formation
- Implements comprehensive supervision trees for fault tolerance
- Uses Swarm for distributed process management across cluster nodes

## Important Files

- `lib/application.ex`: Application entry point and main supervisor
- `lib/ex_esdb_gater/system.ex`: Primary system supervisor  
- `lib/ex_esdb_gater/api.ex`: Main gateway API and request routing
- `lib/ex_esdb_gater/cluster_monitor.ex`: Cluster health monitoring
- `lib/ex_esdb_gater/pubsub_system.ex`: Multi-instance PubSub management
- `config/runtime.exs`: Runtime configuration with LibCluster topology
- `ADR.md`: Architecture Decision Records documenting design choices
- `PUBSUB_ARCHITECTURE.md`: Detailed PubSub instance architecture
