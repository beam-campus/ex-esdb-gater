# ExESDB Gater Interactive Test Console

An extensive interactive test console for ExESDB Gater that allows comprehensive testing, monitoring, and interaction with the event store system.

## Features

### 🔍 **Observer Management**
- **Create Observers by Stream**: Monitor specific streams or all streams (`$all`)
- **Create Observers by Event Type**: Monitor specific event types (e.g., `temperature_measured:v1`)
- **Create Observers by Event Payload**: Monitor events matching payload patterns (e.g., `%{operator: "John"}`)
- **List Active Observers**: View all running observers with their status
- **Monitor Specific Observer**: Real-time monitoring of individual observers
- **Stop Observers**: Clean shutdown of observer processes

### 🏭 **Producer Management**
- **Start Multiple Producers**: Create event producers for automatic event generation
- **Stop Producers**: Stop individual producers by stream ID
- **Configurable Batch Sizes**: Control event generation rate and volume

### 📡 **Subscription Management**
- **Create Persistent Subscriptions**: Set up durable subscriptions with acknowledgment
- **List Active Subscriptions**: View all active subscriptions in the system
- **Custom Start Positions**: Start subscriptions from specific stream versions

### 📈 **Data Management**
- **View Stream Data**: Browse events from any stream
- **Manual Event Appending**: Add events manually for testing
- **Cluster Status**: Check gateway worker health and connectivity

## Usage

### Starting the Console

From the ExESDB Gater system directory:

```bash
# Option 1: Using the launcher script
./start_console.exs

# Option 2: From IEx
iex -S mix
iex> ExESDBGater.Repl.Console.start()
```

### Menu Options

```
========== ExESDB Interactive Console ==========
📊 Observers:
  1. Create Observer by Stream
  2. Create Observer by Event Type
  3. Create Observer by Event Payload
  4. List Active Observers
  5. Monitor Specific Observer
  6. Stop Observer

🏭 Producers:
  7. Start Producers
  8. Stop Producer
  9. List Active Producers

📡 Subscriptions:
  10. Create Subscription
  11. List Subscriptions

📈 Data Management:
  12. View Stream Data
  13. Append Events Manually
  14. Get Cluster Status

🚪 Exit:
  15. Exit Console
```

## Observer Types

### 1. By Stream Observer
Monitors all events in a specific stream:

```
Available streams: ["greenhouse1", "greenhouse2", "greenhouse3", ...]
Special streams: $all (all streams)

Enter stream name (or $all): greenhouse1
Enter observer name: greenhouse1_observer
```

### 2. By Event Type Observer
Monitors specific event types across all streams:

```
Available event types:
  1. temperature_measured:v1
  2. humidity_measured:v1
  3. light_measured:v1
  4. fan_activated:v1
  5. desired_temperature_set:v1
  ... and more

Enter event type: temperature_measured:v1
Enter observer name: temp_observer
```

### 3. By Event Payload Observer
Monitors events with specific payload patterns:

```
Example patterns:
  %{operator: "John"}   - Events with operator John
  %{temperature: 25}    - Events with temperature 25
  %{intensity: _}       - Events with any intensity field

Enter observer name: john_observer
Pattern: %{operator: "John"}
```

## Event Generation

The console uses the greenhouse automation domain for realistic event generation:

### Available Event Types
- `initialized:v1` - Greenhouse initialization
- `temperature_measured:v1` - Temperature readings
- `humidity_measured:v1` - Humidity readings
- `light_measured:v1` - Light level readings
- `fan_activated:v1` / `fan_deactivated:v1` - Fan control
- `light_activated:v1` / `light_deactivated:v1` - Light control
- `heater_activated:v1` / `heater_deactivated:v1` - Heater control
- `sprinkler_activated:v1` / `sprinkler_deactivated:v1` - Sprinkler control
- `desired_temperature_set:v1` - Temperature setpoints
- `desired_humidity_set:v1` - Humidity setpoints
- `desired_light_set:v1` - Light setpoints

### Sample Event Payloads

**Temperature Measurement:**
```elixir
%{
  event_id: "01JGXXX...",
  event_type: "temperature_measured:v1",
  data: %{temperature: 22},
  metadata: %{
    causation_id: "01JGXXX...",
    correlation_id: "01JGXXX..."
  }
}
```

**Operator Action:**
```elixir
%{
  event_id: "01JGXXX...",
  event_type: "desired_temperature_set:v1",
  data: %{temperature: 25, operator: "John"},
  metadata: %{...}
}
```

## Real-Time Monitoring

### Observer Output
When monitoring an observer, you'll see real-time event notifications:

```
👁️  Monitoring Observer: greenhouse1_observer
Type: by_stream, Selector: "greenhouse1"
Press Ctrl+C to stop monitoring

SEEN ["greenhouse1:temperature_measured:v1 (v15) => %{temperature: 23}"]
SEEN ["greenhouse1:fan_activated:v1 (v16) => %{intensity: 75}"]
SEEN ["greenhouse1:desired_temperature_set:v1 (v17) => %{operator: "John", temperature: 20}"]
```

### Subscription Output
Persistent subscriptions with acknowledgment:

```
RECEIVED ["my_subscription" "greenhouse1:humidity_measured:v1 v(12) => %{humidity: 65}"]
RECEIVED ["my_subscription" "greenhouse1:light_measured:v1 v(13) => %{light: 80}"]
```

## Testing Scenarios

### 1. Basic Event Flow Testing
1. Start producers: `Option 7`
2. Create stream observer: `Option 1` → `$all`
3. Watch events flow in real-time: `Option 5`

### 2. Event Type Filtering
1. Create event type observer: `Option 2` → `temperature_measured:v1`
2. Start producers: `Option 7`
3. Monitor temperature events only: `Option 5`

### 3. Payload Pattern Matching
1. Create payload observer: `Option 3` → `%{operator: "John"}`
2. Generate events: `Option 13`
3. See only John's actions: `Option 5`

### 4. Subscription Testing
1. Create persistent subscription: `Option 10`
2. Generate events: `Option 7`
3. Verify acknowledgment flow: `Option 11`

## Advanced Features

### Observer Registry
The console maintains an ETS-based registry of all observers:
- Tracks observer names, types, selectors, and PIDs
- Automatic cleanup on observer death
- Status monitoring (running/stopped)

### Process Monitoring
Real-time monitoring of observer processes:
- Live status updates
- Automatic cleanup on process death
- Graceful shutdown handling

### Colorized Output
Rich terminal output with color coding:
- 🟢 Green: Success states, running processes
- 🔴 Red: Errors, stopped processes
- 🟡 Yellow: Warnings, partial states
- 🔵 Blue: Information, data display
- 🟣 Purple: Categories, sections

## Troubleshooting

### Common Issues

**Observer Not Receiving Events:**
1. Check if producers are running: `Option 9`
2. Verify stream names match
3. Check observer status: `Option 4`

**Subscription Not Working:**
1. Verify subscription exists: `Option 11`
2. Check stream has events: `Option 12`
3. Ensure proper acknowledgment

**Console Crashes:**
1. Restart with `./start_console.exs`
2. Check ExESDB Gater connectivity: `Option 14`
3. Verify cluster is running

### Debug Information

Use the cluster status option (`Option 14`) to verify:
- Gateway worker processes are running
- Cluster connectivity is healthy
- Store is accessible

## Clean Shutdown

The console provides graceful shutdown:
- Stops all registered observers
- Cleans up ETS tables
- Exits cleanly with `Option 15`

## Integration with Development

This console integrates seamlessly with:
- Docker Compose development environment
- ExESDB cluster testing
- Gateway load balancing verification
- Event store performance testing

Perfect for:
- Development testing
- Integration testing
- Performance benchmarking
- Event flow debugging
- Real-time monitoring
