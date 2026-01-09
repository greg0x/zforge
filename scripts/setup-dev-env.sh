#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Setting up Z3 Development Environment..."
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
    
    # Ensure we're on dev branch
    if git rev-parse --verify dev &>/dev/null; then
        git checkout dev
        echo "  ✓ Checked out dev branch"
    else
        echo "  ⚠️  dev branch not found, staying on current branch"
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
echo "  • z3 repo:    main (development happens here)"
echo "  • Submodules: dev (z3 development base, pinned to compatible versions)"
echo "  •             main (tracks upstream, sync only)"
echo ""
echo "📝 Next steps:"
echo "  1. Start the stack: ./scripts/dev-start.sh"
echo "  2. Run integration tests: ./tests/integration_test.sh"
echo "  3. Create feature branches from dev: git checkout -b feature/my-change"
echo ""
echo "🔄 Branch workflow:"
echo "  • Daily work:  feature branches from 'dev'"
echo "  • Upstreaming: create branch from 'main', cherry-pick commits"
echo "  • See .cursor/rules/branch_workflow.mdc for details"
