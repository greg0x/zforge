#!/usr/bin/env bash
set -euo pipefail

# Restart Z3 development environment after code changes
# Usage: ./scripts/dev-restart.sh [service]
#   service: optional, rebuild only specific service (zebra|zaino)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "🔄 Restarting Z3 Development Environment..."
echo ""

# Stop services
echo "🛑 Stopping services..."
docker compose down
echo ""

# Rebuild
if [ -n "${1:-}" ]; then
    echo "🔨 Rebuilding $1..."
    docker compose build "$1"
else
    echo "🔨 Rebuilding all services..."
    docker compose build
fi

echo ""
echo "🚀 Starting services..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to initialize..."
sleep 5

# Show status
echo ""
echo "📊 Service Status:"
docker compose ps

echo ""
echo "📝 View logs:"
echo "  docker compose logs -f zebra"
echo "  docker compose logs -f zaino"
echo ""
echo "✨ Restart complete!"
