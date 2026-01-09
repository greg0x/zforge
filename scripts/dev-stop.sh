#!/usr/bin/env bash
set -euo pipefail

# Stop Z3 development environment
# Usage: ./scripts/dev-stop.sh [--clean]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "🛑 Stopping Z3 Development Environment..."
echo ""

# Stop containers
docker compose down

if [ "${1:-}" = "--clean" ]; then
    echo ""
    echo "🧹 Cleaning up volumes (removes all blockchain data)..."
    docker volume rm z3_zebra_data z3_zaino_data z3_shared_cookie_volume 2>/dev/null || true
    echo "✅ Volumes removed"
fi

echo ""
echo "✅ Development environment stopped"
