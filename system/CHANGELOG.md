# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.5.0] - 2025-08-15

### BREAKING CHANGES  
- **Package Separation Complete**: Successfully extracted UI and API components into separate packages:
  - **Dashboard → `ex_esdb_dashboard`**: All Phoenix LiveView dashboard components moved to separate package
  - **gRPC API → `ex_esdb_grpc`**: EventStore-compatible gRPC API extracted to separate package  
  - **Core Focus**: `ex_esdb_gater` now focuses purely on cluster logic, messaging, and PubSub infrastructure

### Added
- **Clean Package Ecosystem**: ExESDB now consists of three focused packages:
  - 🏗️ **`ex_esdb_gater`** (~> 0.5.0) - Core cluster logic and messaging
  - 🎨 **`ex_esdb_dashboard`** (~> 0.1.0) - LiveView UI and monitoring  
  - 🔌 **`ex_esdb_grpc`** (~> 0.1.0) - gRPC API server for external clients

### Removed
- **Dashboard Components**: Moved to `ex_esdb_dashboard` package:
  - `ExESDBGater.Dashboard.ClusterLive` → `ExESDBDashboard.ClusterLive`
  - `ExESDBGater.Dashboard.ClusterStatus` → `ExESDBDashboard.ClusterStatus`  
  - `ExESDBGater.Dashboard` → `ExESDBDashboard`
- **gRPC Components**: Extracted to `ex_esdb_grpc` package (previously in experimental repos)
- **Phoenix Dependencies**: No longer needed in core package

### Fixed
- **Perfect Umbrella Compatibility**: Core package compiles cleanly without any Phoenix dependencies
- **Dependency Conflicts**: Each package has only the dependencies it actually needs
- **Import Conflicts**: No more issues with optional dependencies in business logic apps

### Migration Guide
#### For Core PubSub/API Usage
- **No changes required** - all message modules and PubSub functionality unchanged
- Continue using `{:ex_esdb_gater, "~> 0.5.0"}` as before

#### For Dashboard Users  
```elixir
# Old (0.4.x)
{:ex_esdb_gater, "~> 0.4.0"}

# New (0.5.0+)
{:ex_esdb_gater, "~> 0.5.0"},
{:ex_esdb_dashboard, "~> 0.1.0"}
```

#### For gRPC API Users
```elixir
# Add gRPC API server
{:ex_esdb_gater, "~> 0.5.0"},
{:ex_esdb_grpc, "~> 0.1.0"}
```

### Architecture Benefits
- **🎯 Single Responsibility**: Each package has one clear purpose
- **📦 Flexible Dependencies**: Mix and match packages as needed
- **🔧 Easy Maintenance**: Separate release cycles and dependencies
- **⚡ Lighter Core**: Core package is now dependency-lean
- **🚀 Better Testing**: Each package can be tested independently

## [0.4.1] - 2025-08-15

### BREAKING CHANGES (Superseded by 0.5.0)
- **Dashboard Modules Removed**: Removed Phoenix LiveView dashboard components from core package to eliminate optional dependency issues
- **Temporary State**: This was an intermediate release during package separation

## [0.3.7] - 2025-08-15

### Added
- **Structured Message System**: Implemented comprehensive structured messaging framework for secure inter-component communication:
  - **9 Dedicated Message Modules**: Each PubSub instance now has its own message module with structured payload definitions:
    - `SystemMessages` - System configuration and lifecycle events
    - `HealthMessages` - Health monitoring and status checks
    - `MetricsMessages` - Performance metrics and measurements
    - `LifecycleMessages` - Process and node lifecycle events
    - `SecurityMessages` - Security events and access control
    - `AuditMessages` - Audit trail and compliance events
    - `AlertMessages` - Critical alerts and notifications
    - `DiagnosticsMessages` - Deep diagnostic and debugging info
    - `LoggingMessages` - Log aggregation and distribution
  - **HMAC Security**: Messages are cryptographically signed using SECRET_KEY_BASE to prevent unauthorized nodes from polluting the cluster
  - **Structured Payloads**: Well-defined struct-based message payloads with enforced field types and validation
  - **Broadcasting Helpers**: Secure broadcasting functions with automatic message signing
  - **Validation Helpers**: Message validation functions for receivers with security verification
  - **Helper Functions**: Convenient payload creation functions with automatic timestamps

- **Enhanced Dashboard Integration**: Updated cluster dashboard to use new structured message system:
  - Idiomatic Elixir pattern matching in `handle_info/2` functions
  - Structured message validation for real-time updates
  - Backward compatibility with legacy message formats during transition
  - Enhanced security for dashboard real-time communication

- **Central Message Management**: Added `ExESDBGater.Messages` module for centralized access:
  - Convenient aliases for all message modules
  - Dynamic message routing and validation functions
  - Instance-to-module mapping for programmatic access
  - Comprehensive usage examples and documentation

### Security
- **Message Authentication**: All inter-component messages now include HMAC signatures to prevent tampering
- **Rogue Node Protection**: Cryptographic validation prevents unauthorized nodes from broadcasting false information
- **Configurable Security**: Works with or without SECRET_KEY_BASE (development vs production environments)
- **Constant-time Validation**: Uses `:crypto.hash_equals/2` for secure signature comparison

### Changed
- **Dashboard Message Handling**: Migrated from simple PubSub topics to structured, validated messages
- **Message Format**: Standardized on Phoenix PubSub pattern `{:message_identifier, payload_struct}`
- **Security Model**: Enhanced from basic topic-based messaging to cryptographically signed message validation

### Technical Details
- **Idiomatic Elixir**: Uses proper pattern matching instead of case statements for message handling
- **Struct-based Payloads**: Each message type has a dedicated struct with field documentation
- **Topic Conventions**: Clean topic naming without redundant prefixes (e.g., "cluster_health" not "health_cluster_health")
- **Helper Functions**: Automatic timestamp injection and sensible defaults for message creation
- **Error Handling**: Comprehensive error handling for invalid messages, missing secrets, and validation failures
- **Documentation**: Extensive module documentation with usage examples and security considerations

## [0.3.6] - 2025-08-15

### Added
- **Composable Dashboard Module**: Implemented comprehensive real-time cluster monitoring dashboard with Phoenix LiveView components:
  - `ExESDBGater.Dashboard` - Main module with data aggregation and helper functions
  - `ExESDBGater.Dashboard.ClusterLive` - Full-featured dashboard LiveView with real-time cluster monitoring
  - `ExESDBGater.Dashboard.ClusterStatus` - Compact embeddable LiveComponent widget
  - Real-time updates via Phoenix.PubSub integration with `ClusterMonitor`
  - Cluster health indicators with visual status representations
  - Node monitoring with connectivity status, uptime tracking, and ExESDB node identification
  - Store statistics including stream counts, subscription counts, and node distribution
  - Flexible integration patterns: full dashboard routes, embedded widgets, or custom implementations

- **Dashboard Integration Options**:
  - **Router Integration**: `import ExESDBGater.Dashboard; dashboard_routes()` for complete dashboard routes
  - **Embedded Widget**: `<.live_component module={ExESDBGater.Dashboard.ClusterStatus} id="cluster-status" />` for compact status display
  - **Custom Integration**: Direct use of `Dashboard.get_cluster_data()` for custom implementations
  - **Real-time PubSub**: Subscribe to `"ex_esdb_gater:cluster"` topic for live cluster state updates

- **Enhanced ClusterMonitor**: Extended existing cluster monitoring with PubSub broadcasting:
  - Real-time cluster state change notifications
  - Node connection/disconnection events broadcast to dashboard subscribers
  - Maintains backward compatibility with existing logging functionality

- **Comprehensive Documentation**:
  - `DASHBOARD_INTEGRATION_GUIDE.md` - Complete integration guide with examples for all usage patterns
  - Updated `README.md` with dashboard functionality section
  - Inline module documentation with usage examples
  - CSS styling guidelines and semantic class structure
  - Troubleshooting guide and best practices

### Changed
- **Optional Dependencies**: Added Phoenix LiveView dependencies as optional to avoid forcing web framework choices on consumers:
  - `phoenix_live_view ~> 1.0` (optional)
  - `phoenix_html ~> 4.0` (optional) 
  - `jason ~> 1.2` (optional)

- **ClusterMonitor Enhancement**: Enhanced `ExESDBGater.ClusterMonitor` to broadcast cluster state changes while maintaining existing functionality

### Technical Details
- **Clean Architecture**: Dashboard follows composable library pattern - no forced Phoenix endpoint or infrastructure dependencies
- **Flexible Integration**: Hosting applications maintain full control over Phoenix setup, routing, styling, and authentication
- **Real-time Updates**: Automatic UI updates when nodes connect/disconnect or cluster health changes
- **No Breaking Changes**: All dashboard functionality is completely optional and doesn't affect existing ExESDBGater usage
- **Semantic Styling**: Dashboard components use semantic CSS classes for easy customization and theme integration
- **LiveComponent Pattern**: Proper Phoenix LiveComponent implementation with parent LiveView message forwarding for PubSub updates

## [0.3.3] - 2025-08-12

### Fixed
- **PubSubSystem Umbrella Compatibility**: Fixed issue where multiple ExESDB.System instances in the same node (such as in umbrella applications) would fail to start due to PubSubSystem supervisor name conflicts
- PubSubSystem now gracefully handles `{:already_started, pid}` errors by returning `{:ok, pid}`, enabling proper singleton behavior
- Added comprehensive documentation explaining PubSubSystem singleton design and umbrella application compatibility

### Technical Details
- Updated `ExESDBGater.PubSubSystem.start_link/1` to handle existing supervisor gracefully
- This enables umbrella applications with multiple stores to share the same PubSub infrastructure as intended
- No breaking changes - existing single-store applications continue to work unchanged

## [0.3.0] - 2025-07-27

### Added
- **Comprehensive PubSub Architecture**: Implemented 10 dedicated PubSub instances for different event types:
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

- **PubSub Architecture Documentation**: Added comprehensive documentation (`PUBSUB_ARCHITECTURE.md`) covering:
  - Architecture benefits and design rationale
  - Detailed description of each PubSub instance
  - Consumer patterns and usage examples
  - Best practices and implementation guidelines
  - Monitoring and observability recommendations

- **Comprehensive Test Suite**: Added extensive tests for PubSub system including:
  - Instance availability and uniqueness verification
  - Message isolation between instances and topics
  - Concurrent message handling capabilities
  - Real-world usage pattern validation
  - Error handling and resilience testing
  - Performance characteristics validation

### Changed
- **Enhanced Separation of Concerns**: Migrated from single PubSub instance to specialized instances for better:
  - Event isolation and fault tolerance
  - Independent scaling and configuration
  - Selective subscription capabilities
  - Improved observability and monitoring

### Technical Details
- Updated `ExESDBGater.PubSubSystem` to manage all 10 PubSub instances
- Enhanced test coverage with 22 comprehensive test cases
- Added documentation integration to mix.exs for generated docs
- Maintained backward compatibility with existing PubSub usage

## [Previous Versions]
*Previous changelog entries would go here*
