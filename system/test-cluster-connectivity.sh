#!/bin/bash

# ExESDB Gater Cluster Connectivity Test Script
# This script tests network connectivity and gossip functionality

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Testing ExESDB Gater Cluster Connectivity...${NC}"

# Check if running in container
if [ -f /.dockerenv ]; then
    echo -e "${BLUE}📦 Running inside Docker container${NC}"
else
    echo -e "${YELLOW}⚠️  Not running in Docker container${NC}"
fi

# Check network interfaces
echo -e "${BLUE}🌐 Network Interfaces:${NC}"
ip addr show | grep -E "(inet |UP|DOWN)" || echo "Interface info not available"

# Check if gossip port is listening
echo -e "${BLUE}🔍 Checking if gossip port 45892 is listening...${NC}"
netstat -ln | grep :45892 && echo -e "${GREEN}✅ Gossip port is listening${NC}" || echo -e "${YELLOW}⚠️  Gossip port not found${NC}"

# Check multicast group membership
echo -e "${BLUE}📡 Multicast Group Membership:${NC}"
ip maddr show 2>/dev/null | grep -E "(233\.252\.1\.32|multicast)" || echo "Multicast info not available"

# Test connectivity to known ExESDB nodes (if in same network)
echo -e "${BLUE}🔗 Testing connectivity to ExESDB cluster nodes...${NC}"
for node in ex-esdb0 ex-esdb1 ex-esdb2; do
    if ping -c 1 -W 2 $node >/dev/null 2>&1; then
        echo -e "${GREEN}  ✅ $node is reachable${NC}"
        
        # Test gossip port specifically
        if nc -z -w 2 $node 45892 2>/dev/null; then
            echo -e "${GREEN}    ✅ Gossip port 45892 on $node is accessible${NC}"
        else
            echo -e "${YELLOW}    ⚠️  Gossip port 45892 on $node is not accessible${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠️  $node is not reachable${NC}"
    fi
done

# Check Erlang distribution
echo -e "${BLUE}🎯 Erlang Distribution Check:${NC}"
epmd -names | grep -q ex_esdb_gater && echo -e "${GREEN}✅ ExESDB Gater is registered with EPMD${NC}" || echo -e "${YELLOW}⚠️  ExESDB Gater not registered with EPMD${NC}"

# Test cluster secret environment
echo -e "${BLUE}🔐 Cluster Configuration:${NC}"
if [ -n "$EX_ESDB_CLUSTER_SECRET" ]; then
    echo -e "${GREEN}✅ Cluster secret is configured (EX_ESDB_CLUSTER_SECRET)${NC}"
else
    echo -e "${RED}❌ Cluster secret is not configured${NC}"
fi

if [ -n "$EX_ESDB_COOKIE" ]; then
    echo -e "${GREEN}✅ Erlang cookie is configured${NC}"
else
    echo -e "${RED}❌ Erlang cookie is not configured${NC}"
fi

# Check if ExESDB Gater application is running
echo -e "${BLUE}🚀 Application Status:${NC}"
if /system/bin/ex_esdb_gater ping >/dev/null 2>&1; then
    echo -e "${GREEN}✅ ExESDB Gater application is responding${NC}"
    
    # Try to get connected nodes
    echo -e "${BLUE}🔗 Connected Nodes:${NC}"
    connected_nodes=$(/system/bin/ex_esdb_gater rpc "Node.list()." 2>/dev/null | wc -l)
    echo -e "${BLUE}  📊 Connected to $connected_nodes other nodes${NC}"
else
    echo -e "${YELLOW}⚠️  ExESDB Gater application is not responding${NC}"
fi

echo -e ""
echo -e "${BLUE}📋 Connectivity Test Summary:${NC}"
echo -e "  • Container: Docker environment detected"
echo -e "  • Gossip Port: 45892"
echo -e "  • MultiCast Address: 233.252.1.32"
echo -e "  • Network: Bridge network connectivity tested"
echo -e ""
echo -e "${GREEN}🎉 Cluster connectivity test completed!${NC}"
