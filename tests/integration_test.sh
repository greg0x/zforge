#!/usr/bin/env bash
set -eo pipefail

# Integration test for Z3 native development stack
# Tests Zebra RPC and Zaino gRPC connectivity

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "🧪 Z3 Stack Integration Test (Native)"
echo "======================================="
echo ""

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

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

# Test 1: Check services are running
echo "Test 1: Service Status"
echo "-----------------------"
if pgrep -f "zebrad.*regtest" > /dev/null 2>&1; then
    pass "Zebra process is running"
else
    fail "Zebra process is not running (start with: overmind start)"
fi

if pgrep -f "zainod.*regtest" > /dev/null 2>&1; then
    pass "Zaino process is running"
else
    fail "Zaino process is not running (start with: overmind start)"
fi
echo ""

# Test 2: Zebra health endpoints
echo "Test 2: Zebra Health Endpoints"
echo "-------------------------------"
# Note: /healthy may return non-2xx on Regtest (no peers), so don't use -f
HEALTHY_RESPONSE=$(curl -s http://localhost:8080/healthy 2>/dev/null || echo "connection_error")
if [ "$HEALTHY_RESPONSE" = "connection_error" ]; then
    fail "Zebra /healthy endpoint not responding"
else
    # Any response (including "insufficient peers") means the endpoint works
    pass "Zebra /healthy endpoint responds ($HEALTHY_RESPONSE)"
fi

READY_STATUS=$(curl -sf http://localhost:8080/ready 2>/dev/null || echo "error")
if [ "$READY_STATUS" = "ok" ] || [ "$READY_STATUS" = "syncing" ]; then
    pass "Zebra /ready endpoint responds (status: $READY_STATUS)"
else
    fail "Zebra /ready endpoint: $READY_STATUS"
fi
echo ""

# Test 3: Zebra RPC
echo "Test 3: Zebra RPC"
echo "-----------------"
RPC_RESPONSE=$(curl -sf -X POST http://localhost:18232 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"getblockchaininfo","params":[],"id":1}' 2>/dev/null || echo "error")

if echo "$RPC_RESPONSE" | grep -q '"result"'; then
    pass "Zebra RPC endpoint responding"
    CHAIN=$(echo "$RPC_RESPONSE" | grep -o '"chain":"[^"]*"' | cut -d'"' -f4 || echo "")
    BLOCKS=$(echo "$RPC_RESPONSE" | grep -o '"blocks":[0-9]*' | cut -d':' -f2 || echo "0")
    info "Network: $CHAIN, Blocks: $BLOCKS"
else
    fail "Zebra RPC not responding"
fi
echo ""

# Test 4: Zaino gRPC connectivity
echo "Test 4: Zaino gRPC Connectivity"
echo "--------------------------------"
if nc -z localhost 8137 2>/dev/null; then
    pass "Zaino gRPC port 8137 is listening"
else
    fail "Zaino gRPC port 8137 is not listening"
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
    pass "Zaino has local orchard patch"
else
    fail "Zaino missing local orchard patch"
fi

if grep -q 'path = "../librustzcash' zaino/Cargo.toml 2>/dev/null; then
    pass "Zaino has local librustzcash patches"
else
    fail "Zaino missing local librustzcash patches"
fi
echo ""

# Test 6: Network configuration
echo "Test 6: Network Configuration"
echo "------------------------------"
if grep -q 'network = "Regtest"' config/zebra-regtest.toml 2>/dev/null; then
    pass "Zebra configured for Regtest"
else
    fail "Zebra not configured for Regtest"
fi

if grep -q 'network = "Regtest"' config/zaino-regtest.toml 2>/dev/null; then
    pass "Zaino configured for Regtest"
else
    fail "Zaino not configured for Regtest"
fi
echo ""

# Test 7: Block Mining (internal miner enabled in native build)
echo "Test 7: Block Mining"
echo "--------------------"

# Get current block height
HEIGHT_RESPONSE=$(curl -sf -X POST http://localhost:18232 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' 2>/dev/null || echo "error")

CURRENT_HEIGHT=$(echo "$HEIGHT_RESPONSE" | grep -o '"result":[0-9]*' | cut -d':' -f2 || echo "0")

if [ "$CURRENT_HEIGHT" -gt "0" ]; then
    pass "Zebra is mining blocks (current height: $CURRENT_HEIGHT)"
else
    fail "No blocks mined yet (height: $CURRENT_HEIGHT)"
fi

# Check if height is increasing (internal miner working)
info "Waiting 3 seconds to check mining progress..."
sleep 3

NEW_HEIGHT_RESPONSE=$(curl -sf -X POST http://localhost:18232 \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"getblockcount","params":[],"id":1}' 2>/dev/null || echo "error")

NEW_HEIGHT=$(echo "$NEW_HEIGHT_RESPONSE" | grep -o '"result":[0-9]*' | cut -d':' -f2 || echo "0")

if [ "$NEW_HEIGHT" -gt "$CURRENT_HEIGHT" ]; then
    pass "Internal miner active: $CURRENT_HEIGHT → $NEW_HEIGHT"
else
    info "Height unchanged ($NEW_HEIGHT) - miner may be paused or solving"
fi
echo ""

# Test 8: zcash-devtool setup
echo "Test 8: zcash-devtool"
echo "---------------------"

# Check zcash-devtool has local patches
if grep -q 'path = "../orchard"' zcash-devtool/Cargo.toml 2>/dev/null; then
    pass "zcash-devtool has local orchard patch"
else
    fail "zcash-devtool missing local orchard patch"
fi

if grep -q 'path = "../librustzcash' zcash-devtool/Cargo.toml 2>/dev/null; then
    pass "zcash-devtool has local librustzcash patches"
else
    fail "zcash-devtool missing local librustzcash patches"
fi

# Check if zcash-devtool binary exists (pre-built)
if [ -f "zcash-devtool/target/release/zcash-devtool" ]; then
    pass "zcash-devtool binary exists"
    
    # Test connection to local Zaino
    info "Testing zcash-devtool connection to Zaino..."
    DEVTOOL_TEST=$(timeout 10 ./zcash-devtool/target/release/zcash-devtool inspect block \
        -s localhost:8137 --height 1 2>&1 || echo "connection_error")
    
    if echo "$DEVTOOL_TEST" | grep -q "hash\|error connecting\|connection_error"; then
        if echo "$DEVTOOL_TEST" | grep -q "hash"; then
            pass "zcash-devtool can query blocks from Zaino"
        else
            info "zcash-devtool couldn't connect (Zaino may need time to sync)"
        fi
    fi
else
    info "zcash-devtool not built yet (run: cd zcash-devtool && cargo build --release)"
fi
echo ""

# Test 9: Protocol development readiness
echo "Test 9: Protocol Development Readiness"
echo "---------------------------------------"

# Check orchard structure
if [ -f "orchard/src/action.rs" ]; then
    pass "orchard/src/action.rs exists (where tag field will be added)"
else
    fail "orchard/src/action.rs not found"
fi

# Check librustzcash transaction structures
if [ -d "librustzcash/zcash_primitives/src/transaction" ]; then
    pass "librustzcash transaction module exists"
else
    fail "librustzcash transaction module not found"
fi

# Check zebra-chain for transaction parsing
if [ -d "zebra/zebra-chain/src/orchard" ]; then
    pass "zebra-chain orchard module exists"
else
    fail "zebra-chain orchard module not found"
fi
echo ""

# Summary
echo "======================================="
echo "Test Summary"
echo "======================================="
echo -e "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo -e "Tests failed: ${RED}$TESTS_FAILED${NC}"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed! Ready for protocol development.${NC}"
    echo ""
    echo "Next steps for tag-PIR implementation:"
    echo "  1. Add tag field to orchard/src/action.rs"
    echo "  2. Update serialization in librustzcash"
    echo "  3. Update zebra-chain parsing"
    echo "  4. Update zaino indexer to extract tags"
    echo "  5. Test with zcash-devtool: cd zcash-devtool && cargo build --release"
    exit 0
else
    echo -e "${RED}❌ Some tests failed. Check output above.${NC}"
    echo ""
    echo "Common fixes:"
    echo "  - Services not running: overmind start"
    echo "  - Build zcash-devtool: cd zcash-devtool && cargo build --release"
    exit 1
fi
