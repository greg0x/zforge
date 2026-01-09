#!/bin/zsh
set -e

# Setup Fork Branches for Z3 Development
# ========================================
# This script configures all submodule forks to use:
#   main     → z3-compatible development (DEFAULT)
#   upstream → remote tracking for official repos

cd "$(dirname "$0")/.."
ROOT=$(pwd)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "Z3 Fork Branch Setup"
echo "=========================================="
echo ""

# Target commits for z3 compatibility
# All versions use orchard 0.11, sapling-crypto 0.5, zcash_client_backend 0.20
get_target() {
    case "$1" in
        orchard)       echo "0a71893" ;;           # Release 0.11.0
        librustzcash)  echo "572a91a0f" ;;         # zcash_client_backend 0.20, zcash_keys 0.11
        zcash-devtool) echo "f17ddb0" ;;           # Uses zcash_client_backend 0.20
        *)             echo "" ;;                   # Use current for zebra, zaino
    esac
}

show_state() {
    echo "=== Current Repository State ==="
    echo ""
    for repo in orchard librustzcash zebra zaino zcash-devtool; do
        if [ -d "$ROOT/$repo" ]; then
            cd "$ROOT/$repo"
            branch=$(git branch --show-current 2>/dev/null || echo "detached")
            commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
            
            # Check if main exists
            main_exists="no"
            main_commit=""
            if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
                main_exists="yes"
                main_commit=$(git rev-parse --short main 2>/dev/null)
            fi
            
            # Check if dev exists
            dev_exists="no"
            dev_commit=""
            if git show-ref --verify --quiet refs/heads/dev 2>/dev/null; then
                dev_exists="yes"
                dev_commit=$(git rev-parse --short dev 2>/dev/null)
            fi
            
            echo -e "  ${GREEN}$repo${NC}:"
            echo "    Current: $branch @ $commit"
            [ "$main_exists" = "yes" ] && echo "    main: $main_commit"
            [ "$dev_exists" = "yes" ] && echo "    dev: $dev_commit"
            
            # Show remotes
            if git remote | grep -q upstream; then
                upstream_url=$(git remote get-url upstream 2>/dev/null)
                echo "    upstream: $upstream_url"
            else
                echo -e "    ${RED}upstream: NOT CONFIGURED${NC}"
            fi
            
            # Show target
            target=$(get_target "$repo")
            if [ -n "$target" ]; then
                echo "    target: $target"
            fi
            echo ""
        fi
    done
}

execute_setup() {
    echo "=== Executing Branch Setup ==="
    echo ""
    
    for repo in orchard librustzcash zebra zaino zcash-devtool; do
        if [ ! -d "$ROOT/$repo" ]; then
            echo -e "${RED}  ✗ $repo directory not found${NC}"
            continue
        fi
        
        cd "$ROOT/$repo"
        echo -e "${YELLOW}Setting up $repo...${NC}"
        
        # Ensure upstream remote
        if ! git remote | grep -q upstream; then
            echo -e "  ${RED}ERROR: upstream remote not configured${NC}"
            echo "  Please add upstream remote first"
            continue
        fi
        
        # Fetch upstream
        echo "  Fetching upstream..."
        git fetch upstream --tags 2>/dev/null || git fetch upstream
        
        # Get current dev branch commit if it exists
        dev_commit=""
        if git show-ref --verify --quiet refs/heads/dev 2>/dev/null; then
            dev_commit=$(git rev-parse dev)
            echo "  Found dev branch at ${dev_commit:0:8}"
        fi
        
        # Determine target commit
        target=$(get_target "$repo")
        if [ -z "$target" ]; then
            # Use current dev commit if no specific target
            if [ -n "$dev_commit" ]; then
                target="$dev_commit"
            else
                target=$(git rev-parse HEAD)
            fi
        fi
        
        echo "  Target commit: ${target:0:10}"
        
        # Stash any changes
        git stash 2>/dev/null || true
        
        # Check if main exists
        if git show-ref --verify --quiet refs/heads/main 2>/dev/null; then
            echo "  main branch exists, updating..."
            git checkout main 2>/dev/null || git checkout -b main
            git reset --hard "$target"
        else
            echo "  Creating main branch..."
            git checkout -b main "$target" 2>/dev/null || {
                git checkout --orphan main
                git reset --hard "$target"
            }
        fi
        
        echo -e "  ${GREEN}✓ $repo: main branch set to ${target:0:8}${NC}"
        echo ""
    done
    
    # Now we need to re-apply patches for repos that had them
    echo "=== Checking Patches ==="
    
    for repo in zaino zebra zcash-devtool; do
        cd "$ROOT/$repo"
        echo "  Checking $repo for local patches..."
        
        if grep -q "\[patch.crates-io\]" Cargo.toml 2>/dev/null; then
            echo -e "    ${GREEN}✓ Patches already configured${NC}"
        else
            echo -e "    ${YELLOW}⚠ No patches found - may need manual setup${NC}"
        fi
    done
    
    echo ""
    echo "=== Updating z3 Main Repo Submodules ==="
    cd "$ROOT"
    
    for repo in orchard librustzcash zebra zaino zcash-devtool; do
        if [ -d "$repo" ]; then
            echo "  Staging submodule pointer for $repo..."
            git add "$repo" 2>/dev/null || true
        fi
    done
    
    echo ""
    echo -e "${GREEN}=========================================="
    echo "Setup Complete!"
    echo "==========================================${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Review changes in each submodule"
    echo "  2. Push fork branches (run for each with changes):"
    echo "     cd orchard && git push -u origin main --force"
    echo "     cd ../librustzcash && git push -u origin main --force"
    echo "     cd ../zcash-devtool && git push -u origin main --force"
    echo "  3. Commit z3 repo: git commit -m 'Update submodules to main branches'"
    echo "  4. Test build: cargo build --release -p zainod"
}

# Main
case "${1:-}" in
    --execute)
        show_state
        echo ""
        echo -n "Proceed with setup? (y/N) "
        read confirm
        if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
            execute_setup
        else
            echo "Aborted."
        fi
        ;;
    *)
        show_state
        echo "=========================================="
        echo "To execute the setup, run:"
        echo "  $0 --execute"
        echo "=========================================="
        ;;
esac
