#!/usr/bin/env bash
set -euo pipefail

# Start Z3 development environment
# Usage: ./scripts/dev-start.sh [--rebuild]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

cd "$PROJECT_ROOT"

echo "🚀 Starting Z3 Development Environment..."
echo ""

# Check if TLS certificates exist
if [ ! -f "config/tls/zaino.crt" ] || [ ! -f "config/tls/zaino.key" ]; then
    echo "📜 Generating Zaino TLS certificates..."
    openssl req -x509 -newkey rsa:4096 \
        -keyout config/tls/zaino.key \
        -out config/tls/zaino.crt \
        -sha256 -days 365 -nodes \
        -subj "/CN=localhost" \
        -addext "subjectAltName=DNS:localhost,DNS:zaino,IP:127.0.0.1" \
        2>/dev/null
    echo "✅ TLS certificates generated"
    echo ""
fi

# Check for rebuild flag
if [ "${1:-}" = "--rebuild" ]; then
    echo "🔨 Rebuilding services..."
    docker compose build
    echo ""
fi

# Start services
echo "🐳 Starting Docker containers..."
docker compose up -d

echo ""
echo "⏳ Waiting for services to initialize..."
sleep 5

# Show status
echo ""
echo "📊 Service Status:"
docker compose ps

echo ""
echo "🔍 Quick Health Check:"
if curl -s http://localhost:8080/healthy > /dev/null 2>&1; then
    echo "  ✅ Zebra: Healthy"
else
    echo "  ⏳ Zebra: Starting..."
fi

echo ""
echo "📝 View logs:"
echo "  docker compose logs -f zebra"
echo "  docker compose logs -f zaino"
echo ""
echo "🛑 Stop services:"
echo "  ./scripts/dev-stop.sh"
echo ""
echo "✨ Development environment ready!"
