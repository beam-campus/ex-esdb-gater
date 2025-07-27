# Architecture Decision Records (ADR)

## ADR-001: Multi-Instance PubSub Architecture

**Date:** 2025-07-27

**Status:** Accepted

### Context

ExESDB Gater originally used a single PubSub instance (`:ex_esdb_system`) for all event communication. As the system evolved, several challenges emerged:

1. **Event Type Confusion**: Different types of events (health, metrics, security, audit) were mixed together, making it difficult for consumers to subscribe selectively.

2. **Scalability Concerns**: High-volume events (like metrics) could overwhelm low-volume but critical events (like security alerts).

3. **Fault Isolation**: Issues with one type of event processing could affect all other event types.

4. **Observability Challenges**: Monitoring and debugging were complicated by the lack of separation between different event concerns.

5. **Consumer Complexity**: Applications had to filter and route messages manually, increasing complexity and potential for errors.

### Decision

We will implement a multi-instance PubSub architecture with 10 dedicated instances, each serving a specific purpose:

- `:ex_esdb_events` - Core business events and domain data
- `:ex_esdb_system` - General system-level events (retained for compatibility)
- `:ex_esdb_logging` - Log aggregation and distribution
- `:ex_esdb_health` - Health monitoring and status events
- `:ex_esdb_metrics` - Performance metrics and statistics
- `:ex_esdb_security` - Security events and threat detection
- `:ex_esdb_audit` - Audit trail for compliance requirements
- `:ex_esdb_alerts` - Critical system alerts requiring immediate attention
- `:ex_esdb_diagnostics` - Deep diagnostic information for debugging
- `:ex_esdb_lifecycle` - Process lifecycle events (starts, stops, crashes)

### Consequences

#### Positive

1. **Clear Separation of Concerns**: Each PubSub instance has a well-defined purpose, making the system easier to understand and maintain.

2. **Independent Scaling**: Each instance can be tuned and scaled based on its specific volume and latency requirements.

3. **Selective Subscription**: Consumers can subscribe only to the event types they need, reducing unnecessary processing.

4. **Fault Isolation**: Problems with one event type won't cascade to others, improving overall system resilience.

5. **Enhanced Observability**: Each instance can be monitored independently, providing better insights into system behavior.

6. **Compliance Support**: Dedicated audit and security instances support regulatory and compliance requirements.

7. **Performance Optimization**: High-volume streams (metrics, logs) won't interfere with critical, low-volume streams (alerts, security).

#### Negative

1. **Increased Complexity**: More instances to manage, monitor, and maintain.

2. **Resource Overhead**: Each PubSub instance consumes some memory and processing resources.

3. **Configuration Complexity**: More instances to configure and tune appropriately.

4. **Learning Curve**: Developers need to understand which instance to use for which type of event.

#### Mitigations

1. **Comprehensive Documentation**: Created detailed architecture documentation explaining each instance's purpose and usage patterns.

2. **Consistent Naming**: Used clear, descriptive names for each instance that indicate their purpose.

3. **Extensive Testing**: Implemented comprehensive test suite to ensure proper isolation and functionality.

4. **Backward Compatibility**: Maintained existing `:ex_esdb_system` instance to ensure no breaking changes.

### Implementation Details

- All instances are managed by `ExESDBGater.PubSubSystem` supervisor
- Each instance uses the same underlying Phoenix PubSub technology
- Instances are created using `ExESDBGater.PubSubManager` to ensure singleton behavior
- Comprehensive test coverage ensures proper isolation and functionality

### Alternatives Considered

#### Alternative 1: Topic-Based Routing on Single Instance
**Rejected because:** While simpler to implement, this approach doesn't provide the fault isolation, independent scaling, or selective subscription benefits of separate instances.

#### Alternative 2: External Message Broker (RabbitMQ, Kafka)
**Rejected because:** Adds external dependencies and operational complexity. Phoenix PubSub provides sufficient functionality for our current needs with better integration into the Elixir ecosystem.

#### Alternative 3: Fewer, Broader Categories
**Rejected because:** Testing with 3-5 broader categories showed that we still needed to subdivide them logically, so we chose to be explicit upfront.

### Monitoring and Success Criteria

1. **Instance Isolation**: Each instance operates independently without cross-contamination
2. **Performance**: No degradation in message delivery performance
3. **Resource Usage**: Total resource usage remains within acceptable bounds
4. **Developer Experience**: Clear guidelines and examples for choosing appropriate instances
5. **Operational Excellence**: Monitoring and alerting work effectively for each instance

### Related Documents

- [PUBSUB_ARCHITECTURE.md](PUBSUB_ARCHITECTURE.md) - Detailed technical documentation
- [CHANGELOG.md](CHANGELOG.md) - Implementation history and changes
