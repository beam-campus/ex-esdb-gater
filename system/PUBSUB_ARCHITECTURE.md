# ExESDB Gater PubSub Architecture

## Overview

ExESDB Gater implements a comprehensive PubSub (Publish-Subscribe) architecture using multiple dedicated Phoenix PubSub instances. This design provides superior decoupling, observability, and system resilience by segregating different types of events into specialized communication channels.

## Architecture Benefits

### 1. **Separation of Concerns**
Each PubSub instance handles a specific type of event, preventing cross-contamination and ensuring that consumers only receive the events they need. This reduces noise and improves system clarity.

### 2. **Independent Scaling**
Different event types have different volume characteristics and consumer patterns. Separate instances allow for independent tuning, monitoring, and scaling based on specific requirements.

### 3. **Selective Subscription**
Consumers can subscribe only to the event types they care about, reducing unnecessary message processing and improving performance.

### 4. **Fault Isolation**
Issues with one type of event (e.g., high-volume metrics) won't affect other critical systems (e.g., security alerts), improving overall system resilience.

### 5. **Independent Configuration**
Each PubSub instance can have different retention policies, routing strategies, and performance characteristics optimized for its specific use case.

## PubSub Instances

### Core Event Data
**Instance:** `:ex_esdb_events`

**Purpose:** Handles core business events and domain data flowing through the ExESDB system.

**Typical Topics:**
- `event_stream:#{stream_id}`
- `projection_updates:#{projection_name}`
- `aggregate_events:#{aggregate_id}`

**Use Cases:**
- Event sourcing data distribution
- Real-time projection updates
- Inter-service communication for business logic

**Volume:** High - Core business events
**Criticality:** High - Essential for business operations

---

### System Events
**Instance:** `:ex_esdb_system`

**Purpose:** General system-level events that don't fit into other specific categories.

**Typical Topics:**
- `system_status:#{component}`
- `configuration_changes:#{service}`
- `service_discovery:#{node}`

**Use Cases:**
- Service coordination
- Configuration management
- General system notifications

**Volume:** Medium - Periodic system events
**Criticality:** Medium - Important for system coordination

---

### Log Aggregation
**Instance:** `:ex_esdb_logging`

**Purpose:** Centralized log message distribution and aggregation across the system.

**Typical Topics:**
- `logs:#{service}:#{level}`
- `structured_logs:#{component}`
- `error_reports:#{service}`

**Use Cases:**
- Centralized logging
- Log analysis and monitoring
- Debugging and troubleshooting

**Volume:** Very High - Continuous log streams
**Criticality:** Medium - Important for observability

---

### Health Monitoring
**Instance:** `:ex_esdb_health`

**Purpose:** Health status and monitoring events for system components and processes.

**Typical Topics:**
- `subscription_health:#{store_id}:#{subscription_name}`
- `process_health:#{component}`
- `circuit_breaker_status:#{service}`

**Use Cases:**
- Subscription proxy health monitoring
- Circuit breaker status tracking
- Component health dashboards
- Automated health checks

**Volume:** Medium - Regular health check events
**Criticality:** High - Critical for system reliability

**Example Event:**
```elixir
%{
  store_id: "production_store",
  subscription_name: "user_projection",
  event_type: :registration_success,
  timestamp: 1672531200000,
  metadata: %{
    proxy_pid: #PID<0.123.0>,
    subscriber_pid: #PID<0.124.0>,
    registration_time: 1672531200000
  }
}
```

---

### Performance Metrics
**Instance:** `:ex_esdb_metrics`

**Purpose:** Performance metrics, statistics, and measurement data for system optimization.

**Typical Topics:**
- `subscription_metrics:#{store_id}:#{subscription_name}`
- `performance_metrics:#{component}`
- `throughput_stats:#{service}`

**Use Cases:**
- Performance monitoring
- Capacity planning
- SLA compliance tracking
- System optimization

**Volume:** Very High - Continuous metrics streams
**Criticality:** Medium - Important for optimization

**Example Event:**
```elixir
%{
  store_id: "production_store",
  subscription_name: "user_projection",
  event_type: :registration_attempt,
  timestamp: 1672531200000,
  metadata: %{
    result: :ok,
    source: :subscription_metrics,
    processing_time_ms: 45
  }
}
```

---

### Security Events
**Instance:** `:ex_esdb_security`

**Purpose:** Security-related events including authentication, authorization, and threat detection.

**Typical Topics:**
- `security_events:authentication`
- `security_events:authorization`
- `threat_detection:#{service}`
- `access_violations:#{resource}`

**Use Cases:**
- Security monitoring
- Threat detection
- Compliance reporting
- Incident response

**Volume:** Low to Medium - Security events as they occur
**Criticality:** Very High - Critical for security

**Example Event:**
```elixir
%{
  event_type: :authentication_failure,
  user_id: "suspicious_user",
  ip_address: "***REDACTED***",
  timestamp: 1672531200000,
  reason: :invalid_credentials,
  metadata: %{
    attempt_count: 5,
    user_agent: "curl/7.68.0"
  }
}
```

---

### Audit Trail
**Instance:** `:ex_esdb_audit`

**Purpose:** Audit trail events for compliance, governance, and regulatory requirements.

**Typical Topics:**
- `audit_trail:user_actions`
- `audit_trail:admin_operations`
- `compliance_events:#{regulation}`

**Use Cases:**
- Regulatory compliance
- Audit reporting
- Governance tracking
- Legal requirements

**Volume:** Medium - User and admin actions
**Criticality:** Very High - Required for compliance

**Example Event:**
```elixir
%{
  event_type: :user_action,
  user_id: "admin_user",
  action: :delete_subscription,
  resource: "subscription_123",
  timestamp: 1672531200000,
  metadata: %{
    store_id: "production_store",
    ip_address: "***REDACTED***",
    session_id: "sess_abc123"
  }
}
```

---

### Critical Alerts
**Instance:** `:ex_esdb_alerts`

**Purpose:** High-priority alerts and notifications that require immediate attention.

**Typical Topics:**
- `system_alerts:critical`
- `system_alerts:warning`
- `incident_alerts:#{severity}`

**Use Cases:**
- Incident management
- Pager duty integration
- Emergency notifications
- SLA breach alerts

**Volume:** Low - Only critical situations
**Criticality:** Very High - Requires immediate action

**Example Event:**
```elixir
%{
  event_type: :critical_alert,
  severity: :high,
  component: :subscription_system,
  message: "Circuit breaker opened for multiple subscriptions",
  timestamp: 1672531200000,
  metadata: %{
    affected_subscriptions: 5,
    estimated_impact: "50% of real-time projections offline",
    escalation_required: true
  }
}
```

---

### Diagnostic Information
**Instance:** `:ex_esdb_diagnostics`

**Purpose:** Deep diagnostic information for debugging, profiling, and system analysis.

**Typical Topics:**
- `diagnostics:performance_trace`
- `diagnostics:memory_analysis`
- `diagnostics:connection_pool`

**Use Cases:**
- Performance profiling
- Memory analysis
- Connection monitoring
- Deep system debugging

**Volume:** Variable - Can be very high during debugging
**Criticality:** Low - Diagnostic purposes only

---

### Process Lifecycle
**Instance:** `:ex_esdb_lifecycle`

**Purpose:** Process lifecycle events including starts, stops, crashes, and supervision tree changes.

**Typical Topics:**
- `process_lifecycle:subscription_proxies`
- `process_lifecycle:supervisors`
- `process_lifecycle:#{component}`

**Use Cases:**
- Process monitoring
- Supervision tree analysis
- Crash detection and recovery
- System administration

**Volume:** Medium - Process lifecycle events
**Criticality:** High - Important for system stability

**Example Event:**
```elixir
%{
  event_type: :process_started,
  process_type: :subscription_proxy,
  pid: #PID<0.789.0>,
  timestamp: 1672531200000,
  metadata: %{
    store_id: "production_store",
    subscription_name: "user_projection",
    supervisor: #PID<0.456.0>,
    restart_count: 0
  }
}
```

## Consumer Patterns

### Health Dashboard Consumer
```elixir
Phoenix.PubSub.subscribe(:ex_esdb_health, "subscription_health:*")
Phoenix.PubSub.subscribe(:ex_esdb_lifecycle, "process_lifecycle:*")
```

### Security Operations Center (SOC)
```elixir
Phoenix.PubSub.subscribe(:ex_esdb_security, "security_events:*")
Phoenix.PubSub.subscribe(:ex_esdb_audit, "audit_trail:*")
Phoenix.PubSub.subscribe(:ex_esdb_alerts, "system_alerts:critical")
```

### Performance Monitoring
```elixir
Phoenix.PubSub.subscribe(:ex_esdb_metrics, "subscription_metrics:*")
Phoenix.PubSub.subscribe(:ex_esdb_diagnostics, "diagnostics:performance_trace")
```

### Incident Response
```elixir
Phoenix.PubSub.subscribe(:ex_esdb_alerts, "system_alerts:*")
Phoenix.PubSub.subscribe(:ex_esdb_health, "subscription_health:*")
Phoenix.PubSub.subscribe(:ex_esdb_lifecycle, "process_lifecycle:*")
```

## Implementation Details

### PubSub Manager
The system uses `ExESDBGater.PubSubManager` to ensure that PubSub instances are created only once and shared across multiple supervisors. This prevents duplication and ensures consistent behavior.

### Topic Naming Conventions
- Use colons (`:`) to separate topic hierarchy levels
- Include relevant identifiers (store_id, subscription_name, etc.)
- Use consistent naming patterns within each instance

### Message Format
All events should follow a consistent structure:
```elixir
{:event_type, %{
  # Common fields
  timestamp: System.system_time(:millisecond),
  # Event-specific data
  ...
}}
```

### Error Handling
All PubSub operations are wrapped in try-catch blocks to prevent failures from affecting the primary business logic. Failed publications are logged but don't interrupt normal operation.

## Monitoring and Observability

### Metrics to Track
- Message throughput per instance
- Consumer lag and processing times
- Failed publications
- Instance availability and health

### Alerting
- High message volumes that might indicate issues
- Failed publications above threshold
- Instance unavailability
- Consumer disconnections

## Best Practices

### For Publishers
1. Always use appropriate PubSub instance for event type
2. Include comprehensive metadata for debugging
3. Handle publication failures gracefully
4. Use consistent topic naming

### For Consumers
1. Subscribe only to necessary topics
2. Handle message processing failures gracefully
3. Implement backpressure mechanisms for high-volume streams
4. Use appropriate acknowledgment patterns

### For Operations
1. Monitor each instance independently
2. Set up appropriate alerting thresholds
3. Regular health checks for all instances
4. Capacity planning based on volume patterns

## Migration and Compatibility

When adding new event types or modifying existing ones:
1. Use additive changes when possible
2. Maintain backward compatibility
3. Version event schemas appropriately
4. Coordinate changes with consumer teams

## Testing

The system includes comprehensive tests for:
- Instance isolation and independence
- Message routing and delivery
- Error handling and resilience
- Performance characteristics
- Typical usage patterns

See `test/ex_esdb_gater/pubsub_instances_test.exs` for detailed test coverage.
