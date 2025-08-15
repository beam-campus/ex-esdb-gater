# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
