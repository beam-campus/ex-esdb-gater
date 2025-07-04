#!/bin/bash

# ExESDGater Manager - Simplified cluster management for ExESDGater
# This script provides easy management of ExESDGater instances and development tools

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Environment mode (dev/prod)
ENVIRONMENT_MODE="dev"

# Service configurations
declare -A SERVICES=(
    ["gater"]="ex-esdb-network.yaml,ex-esdb-gater.yaml,ex-esdb-gater-override.yaml,gater,ExESDGater instance"
    ["tools"]="livebook.yml,excalidraw.yml,networks.yml,tools,Development tools"
)

# Function to print colored text
print_color() {
    local color=$1
    local text=$2
    echo -e "${color}${text}${NC}"
}

# Helper function to parse service configuration
get_service_config() {
    local service_name=$1
    local config_type=$2  # project, description, files
    
    IFS=',' read -ra config <<< "${SERVICES[$service_name]}"
    
    case $config_type in
        "project") echo "${config[3]}" ;;
        "description") echo "${config[4]}" ;;
        "files") echo "${config[0]},${config[1]},${config[2]}" ;;
    esac
}

# Function to print header
print_header() {
    clear
    print_color $CYAN "╔══════════════════════════════════════════════════════════════╗"
    print_color $CYAN "║                    ExESDGater Manager                        ║"
    print_color $CYAN "║                                                              ║"
    print_color $CYAN "║              Gateway & Development Tools                     ║"
    print_color $CYAN "╚══════════════════════════════════════════════════════════════╝"
    echo
}

# Function to get service status
get_service_status() {
    local service_name=$1
    local project_name=$2
    
    # Check for running containers in this project
    local running_containers=$(docker ps --filter "label=com.docker.compose.project=$project_name" --format "{{.Names}}" | wc -l 2>/dev/null || echo "0")
    local total_containers=$(docker ps -a --filter "label=com.docker.compose.project=$project_name" --format "{{.Names}}" | wc -l 2>/dev/null || echo "0")
    
    if [[ $running_containers -eq 0 ]] && [[ $total_containers -eq 0 ]]; then
        echo -e "${BLUE}●${NC} Not created"
    elif [[ $running_containers -eq 0 ]]; then
        echo -e "${RED}●${NC} Stopped ($total_containers containers)"
    elif [[ $running_containers -eq $total_containers ]] && [[ $total_containers -gt 0 ]]; then
        echo -e "${GREEN}●${NC} Running ($running_containers containers)"
    else
        echo -e "${YELLOW}●${NC} Partial ($running_containers/$total_containers containers)"
    fi
}

# Function to show service status
show_status() {
    print_header
    print_color $WHITE "Current Service Status:"
    echo
    
    for service in "${!SERVICES[@]}"; do
        local project=$(get_service_config $service "project")
        local description=$(get_service_config $service "description")
        
        printf "  %-12s %s %s\\n" "$service" "$(get_service_status $service $project)" "($description)"
    done
    
    echo
    print_color $CYAN "Network Status:"
    if docker network ls | grep -q "ex-esdb-net"; then
        echo -e "  ex-esdb-net    ${GREEN}●${NC} Available"
    else
        echo -e "  ex-esdb-net    ${RED}●${NC} Not found"
    fi
    
    echo
    print_color $CYAN "Volume Status:"
    if [[ -d "/volume" ]]; then
        local size=$(du -sh /volume 2>/dev/null | cut -f1 2>/dev/null || echo "unknown")
        echo -e "  /volume        ${GREEN}●${NC} Available ($size)"
    else
        echo -e "  /volume        ${RED}●${NC} Not found"
    fi
}

# Function to start a service
start_service() {
    local service_name=$1
    local files=$(get_service_config $service_name "files")
    local project=$(get_service_config $service_name "project")
    local description=$(get_service_config $service_name "description")
    
    print_color $YELLOW "Starting $service_name ($description)..."
    echo
    
    # Convert comma-separated files to -f arguments
    local compose_args=""
    IFS=',' read -ra file_array <<< "$files"
    for file in "${file_array[@]}"; do
        if [[ -f "$SCRIPT_DIR/$file" ]]; then
            compose_args="$compose_args -f $file"
        else
            print_color $RED "Error: File $file not found!"
            return 1
        fi
    done
    
    # Create necessary directories
    if [[ "$service_name" == "tools" ]]; then
        print_color $CYAN "Creating directories for development tools..."
        sudo mkdir -p /volume/excalidraw/data
        sudo chown "$USER" -R /volume/ 2>/dev/null || true
    fi
    
    # Start the service
    cd "$SCRIPT_DIR"
    
    # Stop first to ensure clean state
    docker-compose $compose_args --profile $service_name -p $project down 2>/dev/null || true
    
    # Start the service
    if [[ "$service_name" == "gater" ]]; then
        # Load environment variables if available
        if [[ -f "../ex-esdb/dev-env/.env.cluster" ]]; then
            print_color $CYAN "Loading cluster environment from ExESDB..."
            source ../ex-esdb/dev-env/.env.cluster
        fi
        
        docker-compose $compose_args --profile gater -p $project up --remove-orphans --build -d
    else
        docker-compose $compose_args --profile $service_name -p $project up --remove-orphans --build -d
    fi
    
    if [[ $? -eq 0 ]]; then
        print_color $GREEN "✓ $service_name started successfully!"
        
        # Show access information
        if [[ "$service_name" == "tools" ]]; then
            echo
            print_color $CYAN "Access Information:"
            echo "  • Livebook: http://localhost:8080"
            echo "  • Excalidraw: http://localhost:8081"
        elif [[ "$service_name" == "gater" ]]; then
            echo
            print_color $CYAN "ExESDGater is now running and should automatically discover ExESDB cluster nodes"
        fi
    else
        print_color $RED "✗ Failed to start $service_name"
    fi
}

# Function to stop a service
stop_service() {
    local service_name=$1
    local files=$(get_service_config $service_name "files")
    local project=$(get_service_config $service_name "project")
    local description=$(get_service_config $service_name "description")
    
    print_color $YELLOW "Stopping $service_name ($description)..."
    echo
    
    # Convert comma-separated files to -f arguments
    local compose_args=""
    IFS=',' read -ra file_array <<< "$files"
    for file in "${file_array[@]}"; do
        if [[ -f "$SCRIPT_DIR/$file" ]]; then
            compose_args="$compose_args -f $file"
        fi
    done
    
    cd "$SCRIPT_DIR"
    docker-compose $compose_args --profile $service_name -p $project down
    
    if [[ $? -eq 0 ]]; then
        print_color $GREEN "✓ $service_name stopped successfully!"
    else
        print_color $RED "✗ Failed to stop $service_name"
    fi
}

# Function to restart a service
restart_service() {
    local service_name=$1
    stop_service $service_name
    echo
    start_service $service_name
}

# Function to show logs
show_logs() {
    local service_name=$1
    local project=$(get_service_config $service_name "project")
    
    print_color $YELLOW "Showing logs for $service_name..."
    echo
    print_color $CYAN "Press Ctrl+C to exit log view"
    echo
    
    docker-compose -p $project logs -f
}

# Function to clean all data
clean_all_data() {
    print_color $RED "⚠️  WARNING: This will delete ALL development data!"
    echo
    read -p "Are you sure you want to continue? (yes/no): " confirm
    
    if [[ "$confirm" == "yes" ]]; then
        print_color $YELLOW "Stopping all services..."
        for service in "${!SERVICES[@]}"; do
            stop_service $service > /dev/null 2>&1
        done
        
        print_color $YELLOW "Removing data directories..."
        sudo rm -rf /volume/* 2>/dev/null || true
        
        print_color $YELLOW "Removing Docker volumes..."
        docker volume prune -f
        
        print_color $GREEN "✓ All data cleaned successfully!"
    else
        print_color $CYAN "Operation cancelled."
    fi
}

# Function to show resource usage
show_resource_usage() {
    print_color $YELLOW "Docker Resource Usage:"
    echo
    
    # Show running containers
    print_color $CYAN "Running Containers:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(NAMES|gater|livebook|excalidraw)"
    echo
    
    # Show resource consumption
    print_color $CYAN "Resource Consumption:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep -E "(CONTAINER|gater|livebook|excalidraw)"
    echo
    
    # Show disk usage
    print_color $CYAN "Volume Usage:"
    docker system df
}

# Function to check cluster connectivity
check_cluster_connectivity() {
    print_color $YELLOW "Checking ExESDGater cluster connectivity..."
    echo
    
    # Check if gater is running
    local gater_container=$(docker ps --filter "name=ex-esdb-gater" --format "{{.Names}}" 2>/dev/null)
    
    if [[ -z "$gater_container" ]]; then
        print_color $RED "ExESDGater container is not running!"
        return 1
    fi
    
    print_color $CYAN "Checking connected nodes..."
    docker exec "$gater_container" /bin/sh -c "echo 'Node.list().' | /opt/ex_esdb_gater/bin/ex_esdb_gater rpc" 2>/dev/null || {
        print_color $RED "Failed to check node connections"
        return 1
    }
    
    print_color $GREEN "✓ Cluster connectivity check complete"
}

# Function to show main menu
show_menu() {
    print_header
    show_status
    echo
    print_color $WHITE "Available Actions:"
    echo
    print_color $GREEN "  [s] Show Status"
    print_color $GREEN "  [u] Show Resource Usage"
    print_color $GREEN "  [c] Check Cluster Connectivity"
    echo
    print_color $BLUE "  [1] Start ExESDGater"
    print_color $BLUE "  [2] Start Development Tools"
    print_color $BLUE "  [a] Start All Services"
    echo
    print_color $YELLOW "  [3] Stop ExESDGater"
    print_color $YELLOW "  [4] Stop Development Tools"
    print_color $YELLOW "  [z] Stop All Services"
    echo
    print_color $PURPLE "  [r1] Restart ExESDGater"
    print_color $PURPLE "  [r2] Restart Development Tools"
    echo
    print_color $CYAN "  [l1] Show ExESDGater Logs"
    print_color $CYAN "  [l2] Show Tools Logs"
    echo
    print_color $RED "  [clean] Clean All Data"
    print_color $WHITE "  [q] Quit"
    echo
}

# Main loop
main() {
    while true; do
        show_menu
        echo -n "Enter your choice: "
        read -r choice
        echo
        
        case $choice in
            s|S) continue ;;
            u|U) show_resource_usage ;;
            c|C) check_cluster_connectivity ;;
            1) start_service "gater" ;;
            2) start_service "tools" ;;
            a|A) 
                start_service "gater"
                echo
                start_service "tools"
                ;;
            3) stop_service "gater" ;;
            4) stop_service "tools" ;;
            z|Z) 
                for service in "${!SERVICES[@]}"; do
                    stop_service $service
                    echo
                done
                ;;
            r1|R1) restart_service "gater" ;;
            r2|R2) restart_service "tools" ;;
            l1|L1) show_logs "gater" ;;
            l2|L2) show_logs "tools" ;;
            clean|CLEAN) clean_all_data ;;
            q|Q) 
                print_color $GREEN "Goodbye!"
                exit 0
                ;;
            *) 
                print_color $RED "Invalid choice. Please try again."
                ;;
        esac
        
        echo
        print_color $CYAN "Press Enter to continue..."
        read
    done
}

# Check if running as script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
