Commit my changes following project guidelines.

## Workflow

1. **Survey all changes** - Run `./dev git status` to see changes across all submodules
2. **Group by unit of work** - Identify logical commits (one feature/fix per commit)
3. **Handle unknowns** - If you see changes you didn't make or don't understand, ASK me what to do with them
4. **For each commit:**
   - Stage only the files that belong to that unit of work
   - Draft a commit message (show me for approval)
   - Commit using `git commit` in the appropriate repo
5. **Update submodule pointers** - After submodule commits, commit the main repo to update pointers

## Commit Message Format

**Title:** Descriptive, action-oriented, ≤50 chars. No "feat:", "fix:" prefixes.

**Body:** Context and WHY. Do not list what changed (that's in the diff).

```
Add wallet CLI commands for tag-based scanning

Enables PIR pre-filtering of Orchard transactions via detection tags.
Derives tagging keys from Orchard FVK for efficient mobile scanning
without expensive trial decryption.
```

## Multi-repo Handling

This repo has submodules: `orchard/`, `librustzcash/`, `zebra/`, `zaino/`, `zcash-devtool/`

- Commit in submodules FIRST (cd into submodule, git add, git commit)
- Then commit main repo to update submodule pointers
- Use `required_permissions: ['all']` for git operations

## Rules

- ✅ One logical unit of work per commit
- ✅ Code compiles and tests pass
- ✅ Related changes grouped together
- ❌ Don't bundle unrelated changes
- ❌ Don't commit changes you don't understand without asking
