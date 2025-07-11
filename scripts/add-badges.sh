#!/bin/bash

set -euo pipefail

# Script to add badges to README.md
# Usage: ./scripts/add-badges.sh [owner/repo]

# Get repository info
if [ $# -eq 1 ]; then
    REPO=$1
else
    # Try to extract from git remote
    REPO=$(git config --get remote.origin.url | sed 's/.*github.com[:/]\(.*\)\.git/\1/')
fi

if [ -z "$REPO" ]; then
    echo "Error: Could not determine repository. Please provide owner/repo as argument."
    exit 1
fi

echo "Adding badges for repository: $REPO"

# Create README.md if it doesn't exist
if [ ! -f README.md ]; then
    echo "# Go Quality Inspection" > README.md
    echo "" >> README.md
fi

# Check if badges already exist
if grep -q "!\[Build Status\]" README.md; then
    echo "Badges already exist in README.md"
    exit 0
fi

# Create badges section
BADGES=$(cat <<EOF
[![Build Status](https://github.com/$REPO/workflows/Go%20Quality%20Check/badge.svg)](https://github.com/$REPO/actions/workflows/go-quality.yml)
[![Coverage](https://codecov.io/gh/$REPO/branch/main/graph/badge.svg)](https://codecov.io/gh/$REPO)
[![Go Report Card](https://goreportcard.com/badge/github.com/$REPO)](https://goreportcard.com/report/github.com/$REPO)
[![GoDoc](https://pkg.go.dev/badge/github.com/$REPO.svg)](https://pkg.go.dev/github.com/$REPO)
[![License](https://img.shields.io/github/license/$REPO)](https://github.com/$REPO/blob/main/LICENSE)
EOF
)

# Create temporary file
TEMP_FILE=$(mktemp)

# If README starts with #, insert badges after the first line
if head -n 1 README.md | grep -q "^#"; then
    head -n 1 README.md > "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    echo "$BADGES" >> "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    tail -n +2 README.md >> "$TEMP_FILE"
else
    # Otherwise, add badges at the beginning
    echo "$BADGES" > "$TEMP_FILE"
    echo "" >> "$TEMP_FILE"
    cat README.md >> "$TEMP_FILE"
fi

# Replace README.md
mv "$TEMP_FILE" README.md

echo "✓ Badges added successfully to README.md"
echo ""
echo "Next steps:"
echo "1. Review the README.md file"
echo "2. Commit the changes: git add README.md && git commit -m 'Add quality badges to README'"
echo "3. Push to GitHub to see the badges in action"
echo ""
echo "Note: Some badges (like coverage) may require additional setup:"
echo "- Coverage: Set up Codecov integration"
echo "- Go Report Card: Visit https://goreportcard.com/report/github.com/$REPO to generate initial report"