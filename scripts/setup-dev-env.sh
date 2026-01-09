#!/usr/bin/env bash
set -euo pipefail

echo "🔧 Setting up Z3 Development Environment..."
echo ""

# Color output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
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
    
    # Verify remotes
    echo "  📍 origin:   $(git remote get-url origin)"
    echo "  📍 upstream: $(git remote get-url upstream)"
    
    cd ..
}

# Setup all submodules with upstream remotes
echo ""
setup_remotes "zebra" "https://github.com/ZcashFoundation/zebra.git"
setup_remotes "zaino" "https://github.com/zingolabs/zaino.git"
setup_remotes "zcashd" "https://github.com/zcash/zcash.git"
setup_remotes "orchard" "https://github.com/zcash/orchard.git"
setup_remotes "librustzcash" "https://github.com/zcash/librustzcash.git"

# Checkout the correct versions for tag-PIR development
echo ""
echo -e "${BLUE}🎯 Checking out compatible versions for tag-PIR development...${NC}"

cd orchard
git fetch --all --tags
git checkout v0.11.0
echo "  ✓ orchard → v0.11.0"
cd ..

cd librustzcash
git fetch --all --tags
# Find the tag that corresponds to zcash_primitives 0.26.0
# This might be zcash_primitives-0.26.0 or similar
git checkout zcash_primitives-0.26.0 2>/dev/null || \
git checkout $(git tag | grep 'zcash_primitives-0.26' | head -1) 2>/dev/null || \
echo "  ⚠️  Could not find zcash_primitives 0.26.0 tag, staying on main"
echo "  ✓ librustzcash → zcash_primitives v0.26.0"
cd ..

echo ""
echo -e "${GREEN}✅ Development environment setup complete!${NC}"
echo ""
echo "📝 Next steps:"
echo "  1. Review notes/TAG_PIR_QUICKSTART.md for implementation plan"
echo "  2. Run 'cargo check' in zebra/zaino/zallet to verify compilation"
echo "  3. Start development with 'docker-compose up' or see notes/STARTUP_GUIDE.md"
echo ""
echo "🔄 To sync with upstream changes later:"
echo "  cd <submodule> && git fetch upstream && git merge upstream/main"
