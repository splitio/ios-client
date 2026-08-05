#!/bin/bash

# Split SDK Release Preparation Script
# Usage: ./scripts/release.sh <version>
# Example: ./scripts/release.sh 3.0.0-rc1

# Branch name constants - update these if branch naming changes
MASTER_BRANCH="master"
DEVELOPMENT_BRANCH="development"

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

# Get current date in format: (Jun 5, 2025)
CURRENT_DATE=$(date "+%b %-d, %Y")

# Ensure we're in the repo root directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR/.."

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
  echo "❌ Error: Working directory is not clean. Please commit or stash your changes first."
  exit 1
fi

# Fetch latest changes from remote
echo "📥 Fetching latest changes from remote..."
git fetch origin

# Get current branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)
echo "📑 Current branch: $CURRENT_BRANCH"

# Create release branch from current branch
echo "🌿 Creating branch $RELEASE_BRANCH from $CURRENT_BRANCH..."
git checkout -b $RELEASE_BRANCH

# Check if this is an RC version
IS_RC=false
if [[ "$VERSION" == *"-rc"* ]]; then
  IS_RC=true
fi

# Update Version.swift
echo "📝 Updating Version.swift to $VERSION..."
sed -i '' "s/private static let kVersion = \".*\"/private static let kVersion = \"$VERSION\"/" Split/Common/Utils/Version.swift

# Update Split.podspec
echo "📝 Updating Split.podspec to $VERSION..."
sed -i '' "s/s.version          = '.*'/s.version          = '$VERSION'/" Split.podspec

# Update CHANGES.txt if not an RC version
if [ "$IS_RC" = false ]; then
  echo "📝 Updating CHANGES.txt..."
  
  # Prompt for changes
  echo ""
  echo "Please enter the changes for version $VERSION (one per line)"
  echo "Press Enter twice when done (or just press Enter to skip)"
  echo ""
  
  CHANGES=""
  while true; do
    read -r line
    
    # Break on empty line
    if [ -z "$line" ]; then
      if [ -z "$CHANGES" ]; then
        # No changes were entered, just break
        break
      else
        # Confirm if done
        read -r -p "Are you done entering changes? (y/n): " confirm
        if [[ "$confirm" =~ ^[Yy] ]]; then
          break
        fi
      fi
    else
      # Add the line to changes
      if [ -z "$CHANGES" ]; then
        CHANGES="- $line"
      else
        CHANGES="$CHANGES\n- $line"
      fi
    fi
  done
  
  # Create the new entry
  CURRENT_DATE=$(LC_ALL=C date "+%b %-d, %Y")
  NEW_ENTRY="$VERSION: ($CURRENT_DATE)"
  if [ -n "$CHANGES" ]; then
    NEW_ENTRY="$NEW_ENTRY\n$CHANGES"
  fi
  
  # Insert at the beginning of the file
  sed -i '' "1s/^/$NEW_ENTRY\n\n/" CHANGES.txt
  
  # Add CHANGES.txt to the commit
  git add CHANGES.txt
fi

# Commit changes
echo "💾 Committing changes..."
if [ "$IS_RC" = false ]; then
  git add Split/Common/Utils/Version.swift Split.podspec CHANGES.txt
  git commit -m "chore: Update version to $VERSION and update CHANGES.txt"
else
  git add Split/Common/Utils/Version.swift Split.podspec
  git commit -m "chore: Update version to $VERSION"
fi

# Push changes
echo "📤 Pushing branch to remote..."
git push origin $RELEASE_BRANCH

# Harness Code repo location - parsed dynamically from the remote URL
REMOTE_URL=$(git remote get-url origin)
# Strip https://host/ OR user@host: prefix, and any trailing .git
HARNESS_PATH=$(echo "$REMOTE_URL" | sed -E 's#^https?://[^/]+/##; s#^[^@]+@[^:]+:##; s#\.git$##')
HARNESS_ACCOUNT=$(echo "$HARNESS_PATH" | cut -d'/' -f1)
HARNESS_ORG=$(echo "$HARNESS_PATH" | cut -d'/' -f2)
HARNESS_PROJECT=$(echo "$HARNESS_PATH" | cut -d'/' -f3)
HARNESS_REPO=$(echo "$HARNESS_PATH" | cut -d'/' -f4)

# Derive the UI host from the git host, e.g. git0.harness.io -> harness0.harness.io
GIT_HOST=$(echo "$REMOTE_URL" | sed -E 's#^https?://##; s#^[^@]+@##; s#[/:].*##')
HARNESS_UI_HOST=$(echo "$GIT_HOST" | sed -E 's/^git/harness/')

if [ -z "$HARNESS_ACCOUNT" ] || [ -z "$HARNESS_ORG" ] || [ -z "$HARNESS_PROJECT" ] || [ -z "$HARNESS_REPO" ] || [[ "$HARNESS_ACCOUNT" == *@* ]]; then
  echo "❌ Error: Could not parse Harness account/org/project/repo from remote URL: $REMOTE_URL"
  exit 1
fi

# Determine target branch based on RC status
if [ "$IS_RC" = true ]; then
  TARGET_BRANCH="$DEVELOPMENT_BRANCH"
  echo "📊 RC version detected, PR will target the $DEVELOPMENT_BRANCH branch"
else
  TARGET_BRANCH="$MASTER_BRANCH"
  echo "📊 Regular version detected, PR will target the $MASTER_BRANCH branch"
fi

# Create PR URL (Harness Code compare view)
PR_URL="https://$HARNESS_UI_HOST/ng/account/$HARNESS_ACCOUNT/all/code/orgs/$HARNESS_ORG/projects/$HARNESS_PROJECT/repos/$HARNESS_REPO/pulls/compare/$TARGET_BRANCH...$RELEASE_BRANCH"

echo ""
echo "🎉 Release preparation completed successfully!"
echo ""
echo "Opening browser to create pull request..."
open "$PR_URL"
echo ""
echo "Next steps:"
echo "1. Complete the pull request to merge $RELEASE_BRANCH into $TARGET_BRANCH"
echo "2. After merging, the Harness pipeline will create and push the tag"
echo ""
