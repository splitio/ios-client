#!/bin/bash

# Split SDK Release Script
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 3.0.0-rc1

set -e

# Check if version parameter is provided
if [ -z "$1" ]; then
  echo "❌ Error: Version parameter is required"
  echo "Usage: ./scripts/release.sh <version>"
  echo "Example: ./scripts/release.sh 3.0.0-rc1"
  exit 1
fi

VERSION=$1
RELEASE_BRANCH="release/$VERSION"

# Ensure we're in the repo root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "❌ Error: Working directory is not clean. Please commit or stash your changes first."
  exit 1
fi

# Make sure we're on the latest master
echo "📥 Fetching latest changes from remote..."
git fetch origin
git checkout master
git pull origin master

# Create release branch
echo "🌿 Creating branch $RELEASE_BRANCH..."
git checkout -b $RELEASE_BRANCH

# Update Version.swift
echo "📝 Updating Version.swift to $VERSION..."
sed -i '' "s/private static let kVersion = \".*\"/private static let kVersion = \"$VERSION\"/" Split/Common/Utils/Version.swift

# Update Split.podspec
echo "📝 Updating Split.podspec to $VERSION..."
sed -i '' "s/s.version          = '.*'/s.version          = '$VERSION'/" Split.podspec

# Commit changes
echo "💾 Committing changes..."
git add Split/Common/Utils/Version.swift Split.podspec
git commit -m "chore: Update version to $VERSION"

# Create tag
echo "🏷️ Creating tag $VERSION..."
git tag -a "$VERSION" -m "Release $VERSION"

# Push changes and tag
echo "📤 Pushing branch and tag to remote..."
git push origin $RELEASE_BRANCH
git push origin "$VERSION"

# Verify tag in remote
echo "✅ Verifying tag $VERSION exists in remote..."
sleep 2
git fetch --tags

if git ls-remote --tags origin | grep -q "refs/tags/$VERSION$"; then
  echo "✅ Tag $VERSION successfully created in remote"
else
  echo "❌ Failed to verify tag $VERSION in remote"
  exit 1
fi

# Get the remote URL and extract the GitHub repo path
REMOTE_URL=$(git config --get remote.origin.url)
GITHUB_REPO=$(echo $REMOTE_URL | sed -e 's/.*github.com[:/]\(.*\)\.git/\1/')

# If the URL is SSH format (git@github.com:org/repo.git), extract differently
if [[ $GITHUB_REPO == $REMOTE_URL ]]; then
  GITHUB_REPO=$(echo $REMOTE_URL | sed -e 's/.*github.com\/\(.*\)\.git/\1/')
fi

# Create PR URL
PR_URL="https://github.com/$GITHUB_REPO/compare/master...$RELEASE_BRANCH?expand=1"

echo ""
echo "🎉 Release $VERSION completed successfully!"
echo ""
echo "Next steps:"
echo "1. Complete the pull request to merge $RELEASE_BRANCH into master"
echo "2. After merging, the release will be available for distribution"
echo ""
echo "Opening browser to create pull request..."
open "$PR_URL"