#!/usr/bin/env bash
set -eo pipefail

# Simple integration test to verify Z3 stack is working
# Tests Zebra RPC and Zaino gRPC connectivity

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Z3 Stack Integration Test"
echo "=============================="
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✅ PASS${NC}: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

fail() {
    echo -e "${RED}❌ FAIL${NC}: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

info() {
    echo -e "${YELLOW}ℹ${NC}  $1"
}

# Test 1: Check containers are running
echo "Test 1: Container Status"
echo "-------------------------"
if docker compose ps 2>/dev/null | grep "z3_zebra" | grep -q "Up"; then
    pass "Zebra container is running"
else
    fail "Zebra container is not running"
fi

ZAINO_STATUS=$(docker compose ps 2>/dev/null | grep "z3_zaino" || true)
if echo "$ZAINO_STATUS" | grep -q "Up"; then
    pass "Zaino container is running"
else
    fail "Zaino container is not running"
fi
echo ""

# Test 2: Zebra health endpoints
echo "Test 2: Zebra Health Endpoints"
echo "-------------------------------"
HEALTHY_RESPONSE=$(curl -s http://localhost:8080/healthy 2>/dev/null || echo "error")
if [ "$HEALTHY_RESPONSE" != "error" ]; then
    # In Regtest with no peers, "insufficient peers" is expected and acceptable
    if [ "$HEALTHY_RESPONSE" = "ok" ] || echo "$HEALTHY_RESPONSE" | grep -qi "peers"; then
        pass "Zebra /healthy endpoint responds ($HEALTHY_RESPONSE)"
    else
        fail "Zebra /healthy endpoint returned unexpected: $HEALTHY_RESPONSE"
    fi
else
    fail "Zebra /healthy endpoint not responding"
fi

READY_STATUS=$(curl -s http://localhost:8080/ready 2>/dev/null || echo "error")
if [ "$READY_STATUS" = "ok" ] || [ "$READY_STATUS" = "syncing" ]; then
    pass "Zebra /ready endpoint responds (status: $READY_STATUS)"
else
    fail "Zebra /ready endpoint not responding"
fi
echo ""

# Test 3: Zebra RPC
echo "Test 3: Zebra RPC"
echo "-----------------"
RPC_RESPONSE=$(curl -s -X POST http://localhost:18232 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"getblockchaininfo","params":[],"id":1}' 2>/dev/null || echo "error")

if echo "$RPC_RESPONSE" | grep -q "result\|error"; then
    pass "Zebra RPC endpoint is responding"
    
    if echo "$RPC_RESPONSE" | grep -q "result"; then
        # Extract chain and blocks info
        CHAIN=$(echo "$RPC_RESPONSE" | grep -o '"chain":"[^"]*"' | cut -d'"' -f4 || echo "")
        BLOCKS=$(echo "$RPC_RESPONSE" | grep -o '"blocks":[0-9]*' | cut -d':' -f2 || echo "0")
        [ -n "$CHAIN" ] && info "Network: $CHAIN, Blocks: $BLOCKS"
    fi
else
    fail "Zebra RPC not responding"
fi
echo ""

# Test 4: Zaino gRPC (basic connectivity check)
echo "Test 4: Zaino gRPC Connectivity"
echo "--------------------------------"
# Check if port is listening
if nc -z localhost 8137 2>/dev/null; then
    pass "Zaino gRPC port 8137 is listening"
else
    fail "Zaino gRPC port 8137 is not listening"
fi

# Check Zaino logs for successful connection (remove ANSI color codes)
ZAINO_LOGS=$(docker compose logs zaino 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
if echo "$ZAINO_LOGS" | grep -q "Connected to node"; then
    pass "Zaino successfully connected to Zebra"
else
    fail "Zaino not connected to Zebra (check logs)"
fi

# Check for the ready indicator in logs
if echo "$ZAINO_LOGS" | grep -q "ChainState.*Ready"; then
    pass "Zaino ChainState service is ready"
else
    fail "Zaino ChainState service not ready"
fi
echo ""

# Test 5: Local patches verification
echo "Test 5: Local Patches"
echo "---------------------"
if [ -d "orchard" ] && [ -d "librustzcash" ]; then
    pass "Local orchard and librustzcash submodules present"
else
    fail "Local submodules not found"
fi

if grep -q 'path = "../orchard"' zaino/Cargo.toml 2>/dev/null; then
    pass "Zaino Cargo.toml has local orchard patch"
else
    fail "Zaino Cargo.toml missing local orchard patch"
fi

if grep -q 'path = "../librustzcash' zaino/Cargo.toml 2>/dev/null; then
    pass "Zaino Cargo.toml has local librustzcash patches"
else
    fail "Zaino Cargo.toml missing local librustzcash patches"
fi
echo ""

# Test 6: Network configuration
echo "Test 6: Network Configuration"
echo "------------------------------"
NETWORK=$(grep "^NETWORK_NAME=" .env | cut -d'=' -f2)
if [ "$NETWORK" = "Regtest" ]; then
    pass "Network configured for Regtest (protocol development)"
else
    fail "Network is $NETWORK (should be Regtest for protocol work)"
fi
echo ""

# Test 7: End-to-End Block Mining
echo "Test 7: End-to-End Block Mining"
echo "--------------------------------"
info "NOTE: Zebra v3.1.0 does not support internal mining"
info "For mining, use zcashd or wait for Zebra mining support"
info "Skipping mining test..."
echo ""
# TODO: Enable when Zebra supports internal mining or zcashd is added
if false; then

# Get initial block height
INITIAL_HEIGHT_RESPONSE=$(curl -s -X POST http://localhost:18232 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' 2>/dev/null || echo "error")

INITIAL_HEIGHT=$(echo "$INITIAL_HEIGHT_RESPONSE" | grep -o '"result":[0-9]*' | cut -d':' -f2 || echo "0")
info "Initial block height: $INITIAL_HEIGHT"

# Generate a block using Zebra's internal miner (Regtest mode)
info "Generating a block with Zebra's internal miner..."
GENERATE_RESPONSE=$(curl -s -X POST http://localhost:18232 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"generate","params":[1],"id":1}' 2>/dev/null || echo "error")

if echo "$GENERATE_RESPONSE" | grep -q "result"; then
    pass "Zebra generated a block via internal miner"
    BLOCK_HASHES=$(echo "$GENERATE_RESPONSE" | grep -o '"result":\["[^"]*' | sed 's/"result":\["//' || echo "")
    [ -n "$BLOCK_HASHES" ] && info "Block hash: $BLOCK_HASHES"
    
    # Wait for block to be processed
    sleep 2
    
    # Verify Zebra sees the new block
    NEW_HEIGHT_RESPONSE=$(curl -s -X POST http://localhost:18232 \
        -H "Content-Type: application/json" \
        -d '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' 2>/dev/null)
    
    NEW_HEIGHT=$(echo "$NEW_HEIGHT_RESPONSE" | grep -o '"result":[0-9]*' | cut -d':' -f2 || echo "0")
    
    if [ "$NEW_HEIGHT" -gt "$INITIAL_HEIGHT" ]; then
        pass "Zebra block height increased: $INITIAL_HEIGHT → $NEW_HEIGHT"
    else
        fail "Zebra block height did not increase (still at $NEW_HEIGHT)"
    fi
    
    # Check if Zaino indexed the new block (via logs)
    info "Checking if Zaino indexed the new block..."
    sleep 2  # Give Zaino a moment to process
    
    # Look for recent indexing activity in Zaino logs
    ZAINO_RECENT_LOGS=$(docker compose logs zaino --tail=50 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
    
    # Check for height updates or block processing
    if echo "$ZAINO_RECENT_LOGS" | grep -q "Height.*$NEW_HEIGHT\|indexed.*$NEW_HEIGHT\|block.*$NEW_HEIGHT"; then
        pass "Zaino indexed the new block (height $NEW_HEIGHT)"
    elif echo "$ZAINO_RECENT_LOGS" | grep -q "ChainState Service:🟢Ready"; then
        # If Zaino is ready and connected, it should be indexing
        info "Zaino is ready and connected (indexing should be active)"
        pass "Zaino is actively tracking Zebra's chain"
    else
        info "Could not confirm Zaino indexed the block (may need more time)"
    fi
else
    fail "Failed to generate block (internal miner may not be enabled)"
    info "Check docker-compose.yml for ZEBRA_MINING__INTERNAL_MINER=true"
fi
fi  # End of skipped mining test

echo ""

# Summary
echo "=============================="
echo "Test Summary"
echo "=============================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! Stack is working correctly.${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Check output above.${NC}"
    exit 1
fi
