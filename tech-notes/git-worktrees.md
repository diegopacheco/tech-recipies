# Git Worktrees

## What is a Git Worktree?

A git worktree allows you to have multiple working directories attached to a single repository. Each worktree has its own checked-out branch, index, and working directory, but they all share the same `.git` repository data. This means you can work on multiple branches simultaneously without stashing changes or cloning the repo multiple times.

## How it Works

Git worktrees create linked working directories that point back to the main repository. The main repository (bare or regular) maintains a list of all linked worktrees in `.git/worktrees/`. Each worktree:

- Has its own working directory with files checked out
- Has its own HEAD pointing to a specific commit/branch
- Has its own index (staging area)
- Shares objects, refs, and hooks with the main repository
- Cannot have the same branch checked out as another worktree

When you create a worktree, git creates a new directory and a `.git` file (not folder) that points to the main repository's worktree metadata.

## How to Setup

### Create a worktree with a new branch
```bash
git worktree add ../feature-branch -b feature-branch
```

### Create a worktree with an existing branch
```bash
git worktree add ../hotfix-dir hotfix-branch
```

### Create a worktree from a remote branch
```bash
git worktree add ../review-pr origin/pr-branch
```

### List all worktrees
```bash
git worktree list
```

### Remove a worktree
```bash
git worktree remove ../feature-branch
```

### Prune stale worktree references
```bash
git worktree prune
```

### Bare repository setup (recommended for multiple worktrees)
```bash
git clone --bare repo-url repo.git
cd repo.git
git worktree add ../main main
git worktree add ../develop develop
```

## Pros

- Work on multiple branches simultaneously without switching
- No need to stash or commit incomplete work
- Faster than cloning the entire repository multiple times
- Shared object store saves disk space
- Great for code reviews while working on features
- Useful for running tests on one branch while developing on another
- Build processes can run in one worktree while you code in another

## Cons

- Cannot checkout the same branch in multiple worktrees
- Additional disk space for each working directory (files, not git objects)
- Need to manage multiple directories
- Can be confusing to track which worktree you are in
- Some tools and IDEs may not handle multiple worktrees well
- Submodules require extra configuration per worktree
- Worktree paths are absolute, not portable across machines
