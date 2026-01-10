#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Setting up Zforge Development Environment..."
echo ""

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Clone submodules if not already present
echo -e "${BLUE}📦 Initializing submodules...${NC}"
git submodule update --init --recursive

# Configure remotes for each submodule
setup_remotes() {
    local submodule=$1
    local upstream_url=$2
    
    echo -e "${BLUE}🔗 Configuring remotes for ${submodule}...${NC}"
    cd "${submodule}"
    
    # Check if upstream already exists
    if git remote get-url upstream &>/dev/null; then
        echo "  ✓ upstream already configured"
    else
        git remote add upstream "${upstream_url}"
        echo "  ✓ Added upstream: ${upstream_url}"
    fi
    
    # Ensure we're on main branch
    if git rev-parse --verify main &>/dev/null; then
        git checkout main
        echo "  ✓ Checked out main branch"
    else
        echo "  ⚠️  main branch not found, staying on current branch"
    fi
    
    # Verify remotes
    echo "  📍 origin:   $(git remote get-url origin)"
    echo "  📍 upstream: $(git remote get-url upstream)"
    
    cd ..
}

# Setup all submodules with upstream remotes
echo ""
setup_remotes "zebra" "https://github.com/ZcashFoundation/zebra.git"
setup_remotes "zaino" "https://github.com/zingolabs/zaino.git"
setup_remotes "zcash-devtool" "https://github.com/zcash/zcash-devtool.git"
setup_remotes "orchard" "https://github.com/zcash/orchard.git"
setup_remotes "librustzcash" "https://github.com/zcash/librustzcash.git"

echo ""
echo -e "${GREEN}✅ Development environment setup complete!${NC}"
echo ""
echo -e "${YELLOW}📋 Branch Structure:${NC}"
echo "  • zforge repo: main (primary development branch)"
echo "  • Submodules:  main (zforge development, pinned to compatible versions)"
echo "  •             feature/* (your feature branches)"
echo "  •             pr/* (upstream contributions, from upstream/main)"
echo ""
echo "📝 Next steps:"
echo "  ./dev up      # Start services"
echo "  ./dev test    # Run integration tests"
echo "  ./dev status  # Check service health"
echo ""
echo "🔄 Branch workflow:"
echo "  • Daily work:  feature branches from 'main'"
echo "  • Upstreaming: create pr/* branch from 'upstream/main', cherry-pick"
echo "  • See README.md for details"
