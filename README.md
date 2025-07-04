# ExESDB Gater
The ExESDB Gateway API

## Features

ExESDGater is a high-availability gateway service that provides secure, load-balanced access to ExESDB clusters. It acts as a proxy layer between client applications and the ExESDB event store cluster, offering simplified API access and automatic cluster discovery.

### Core Functionality

#### Event Store Operations
- **Stream Management**: Create, read, and manage event streams
- **Event Appending**: Append events to streams with version control
- **Event Retrieval**: Query events from streams with support for forward/backward traversal
- **Stream Versioning**: Get and track stream versions for optimistic concurrency control

#### Subscription Management
- **Multiple Subscription Types**: 
  - `:by_stream` - Subscribe to specific streams
  - `:by_event_type` - Subscribe to events by type
  - `:by_event_pattern` - Subscribe using pattern matching
  - `:by_event_payload` - Subscribe based on event payload content
- **Persistent Subscriptions**: Durable subscriptions that survive restarts
- **Transient Subscriptions**: Temporary subscriptions for short-lived operations
- **Event Acknowledgment**: ACK/NACK support for reliable event processing
- **Replay Capability**: Start subscriptions from any stream version

#### Snapshot Management
- **Snapshot Recording**: Store aggregate snapshots for performance optimization
- **Snapshot Retrieval**: Read snapshots by source UUID, stream UUID, and version
- **Snapshot Deletion**: Remove outdated snapshots
- **Snapshot Listing**: Query available snapshots with filtering

### Cluster Discovery & High Availability

#### LibCluster Integration
ExESDGater uses LibCluster for automatic cluster discovery and formation:

- **Strategy**: Gossip-based multicast discovery
- **Protocol**: UDP multicast on configurable port (default: 45892)
- **Network**: Automatic discovery on shared Docker networks
- **Security**: Shared secret authentication for cluster joining
- **Broadcast Address**: Configurable multicast address (default: 255.255.255.255)

#### Cluster Formation Process
1. **Bootstrap**: ExESDGater starts and initializes LibCluster
2. **Discovery**: Uses gossip multicast to discover ExESDB nodes
3. **Authentication**: Validates cluster membership using shared secrets
4. **Connection**: Establishes Erlang distribution connections to cluster nodes
5. **Monitoring**: Continuously monitors cluster health and node availability

#### High Availability Features
- **Load Balancing**: Automatically distributes requests across available gateway workers
- **Failover**: Seamless handling of node failures and network partitions
- **Health Monitoring**: Real-time cluster status monitoring with detailed logging
- **Auto-Recovery**: Automatic reconnection to recovered cluster nodes
- **Split-Brain Prevention**: Coordinated cluster formation to prevent inconsistencies

### Configuration

#### Environment Variables
- `EX_ESDB_GATER_CONNECT_TO`: Target cluster node (default: current node)
- `EX_ESDB_PUB_SUB`: PubSub process name (default: :ex_esdb_pubsub)
- `EX_ESDB_CLUSTER_SECRET`: Shared secret for cluster authentication
- `EX_ESDB_COOKIE`: Erlang distribution cookie
- `RELEASE_COOKIE`: Release-specific distribution cookie

#### LibCluster Configuration
```elixir
config :libcluster,
  topologies: [
    ex_esdb_gater: [
      strategy: Cluster.Strategy.Gossip,
      config: [
        port: 45_892,
        if_addr: "0.0.0.0",
        multicast_addr: "255.255.255.255",
        broadcast_only: true,
        secret: System.get_env("EX_ESDB_CLUSTER_SECRET")
      ]
    ]
  ]
```

### Architecture

#### Components
- **ExESDBGater.API**: Main API interface and request router
- **ExESDBGater.ClusterMonitor**: Monitors cluster node connections and health
- **ExESDBGater.System**: Supervisor managing all gateway components
- **Gateway Workers**: Distributed workers using Swarm for cluster-wide coordination
- **Phoenix.PubSub**: Event broadcasting and subscription management

#### Worker Distribution
- **Swarm Integration**: Uses Swarm for distributed process management
- **Random Load Balancing**: Requests distributed randomly across available workers
- **Fault Tolerance**: Worker failures handled gracefully with automatic redistribution
- **Cluster-Wide Coordination**: Workers can run on any node in the cluster

### Network Topology

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ExESDB Node   │    │   ExESDB Node   │    │   ExESDB Node   │
│    (node0)      │◄──►│    (node1)      │◄──►│    (node2)      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         ▲                       ▲                       ▲
         │                       │                       │
         │     Gossip Multicast Network (UDP:45892)     │
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   ExESDGater    │    │   ExESDGater    │    │   ExESDGater    │
│   (gateway-1)   │◄──►│   (gateway-2)   │◄──►│   (gateway-3)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Deployment Scenarios

#### Containerized Deployment
- **Docker Compose**: Multi-container setup with shared networks
- **Network Isolation**: Secure communication within Docker bridge networks
- **Service Discovery**: Automatic discovery of ExESDB containers
- **Health Checks**: Container-level health monitoring

#### Production Deployment
- **Multiple Gateways**: Deploy multiple ExESDGater instances for redundancy
- **Load Balancers**: Use external load balancers for client request distribution
- **Monitoring**: Comprehensive logging and metrics collection
- **Security**: Network-level security with firewall rules and VPNs
