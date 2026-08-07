#!/bin/bash
set -e

echo "=== PathDeck Production Git Deployer ==="

WORKSPACE_DIR="$(pwd)"

# 1. Initialize git if not already set up
if [ ! -d "$WORKSPACE_DIR/.git" ]; then
    echo "Initializing local git repository..."
    git init
fi

# 2. Rename or set default branch to main
echo "Renaming default branch to main..."
git branch -M main

# 3. Add remote origin (remove existing first if it exists)
echo "Configuring remote origin link..."
git remote remove origin 2>/dev/null || true
git remote add origin https://github.com/amfi-disable/PathDeck.git

# 4. Stage and commit files (respecting .gitignore)
echo "Staging files..."
git add .

echo "Committing code assets..."
git commit -m "feat: pathdeck release v1.1.1 with xcodeproj project support" || echo "Nothing new to commit."

# 5. Tag release with V1.1.1
echo "Creating annotated release tag V1.1.1..."
git tag -d V1.1.1 2>/dev/null || true
git tag -a V1.1.1 -m "release: pathdeck version v1.1.1"

# 6. Push to remote origin
echo "Pushing branch main and tags to remote origin..."
git push -u origin main --tags --force

echo "========================================="
echo "Deployment successful! PathDeck V1.1.1 is shipped!"
echo "Target remote: https://github.com/amfi-disable/PathDeck.git"
echo "Tag version: V1.1.1"
echo "========================================="
