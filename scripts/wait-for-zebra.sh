#!/usr/bin/env bash
# Wait for Zebra to have at least one block before starting Zaino

set -euo pipefail

# Clear Zaino's state when Zebra is ephemeral (fresh chain each restart)
# This prevents state mismatch between Zaino's persistent DB and Zebra's fresh chain
ZAINO_DATA=".data/zaino"
if [ -d "$ZAINO_DATA" ]; then
    echo "Clearing Zaino state (Zebra is ephemeral)..."
    rm -rf "$ZAINO_DATA"
fi

echo "Waiting for Zebra RPC..."
until nc -z localhost 18232 2>/dev/null; do
    sleep 1
done
echo "Zebra RPC is up, waiting for blocks..."

# Wait for a few blocks (using JSON-RPC 2.0 format)
while true; do
    result=$(curl -sf -X POST \
        -H 'Content-Type: application/json' \
        -d '{"jsonrpc":"2.0","id":"1","method":"getblockcount","params":[]}' \
        http://localhost:18232 2>/dev/null || echo "")
    
    if echo "$result" | grep -q '"result":'; then
        count=$(echo "$result" | sed 's/.*"result":\([0-9]*\).*/\1/')
        if [ "$count" -ge 1 ] 2>/dev/null; then
            echo "Zebra has $count blocks, starting Zaino..."
            break
        fi
    fi
    sleep 2
done

exec "$@"
