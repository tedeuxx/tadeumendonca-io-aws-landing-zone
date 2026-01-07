#!/bin/bash

# Install Git hooks for the project
# Run this script after cloning the repository: ./scripts/install-git-hooks.sh

set -e

echo "🔧 Installing Git hooks for tadeumendonca-io-aws-landing-zone..."

# Create hooks directory if it doesn't exist
mkdir -p .git/hooks

# Install pre-commit hook
echo "📝 Installing pre-commit hook..."
cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit

echo ""
echo "✅ Git hooks successfully installed!"
echo ""
echo "📋 Installed hooks:"
echo "   • pre-commit: Automatically formats Terraform files"
echo ""
echo "🔧 Usage:"
echo "   • Hooks run automatically on git commit"
echo "   • Skip hook: git commit --no-verify"
echo "   • Test hook: .git/hooks/pre-commit"
echo ""
echo "🎉 Your commits will now auto-format Terraform files!"