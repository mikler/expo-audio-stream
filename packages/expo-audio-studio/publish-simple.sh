#!/bin/bash
set -e

# Define color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get absolute path of script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo "Script directory: $SCRIPT_DIR"
cd "$SCRIPT_DIR"

echo -e "${BLUE}Starting simple publication process for @miklermpz/expo-audio-studio...${NC}"

# Check if logged in to npm
if ! npm whoami &> /dev/null; then
    echo -e "${RED}Error: Not logged in to npm. Please run 'npm login' first.${NC}"
    exit 1
fi

NPM_USER=$(npm whoami)
echo -e "${BLUE}Logged in as: $NPM_USER${NC}"

# Clean and build (using npm to avoid workspace issues)
echo -e "${YELLOW}Cleaning and building...${NC}"
npm run clean
npm run build
npm run build:plugin

# Version bump
echo -e "${YELLOW}Current version: $(node -p "require('./package.json').version")${NC}"
read -p "$(echo -e ${YELLOW}Bump version? [patch/minor/major/skip]: ${NC})" version_bump

if [[ $version_bump != "skip" ]]; then
    if [[ $version_bump =~ ^(patch|minor|major)$ ]]; then
        npm version $version_bump --no-git-tag-version
        echo -e "${GREEN}Version bumped to: $(node -p "require('./package.json').version")${NC}"
    else
        echo -e "${RED}Invalid version bump option. Skipping version bump.${NC}"
    fi
fi

# Check package contents
echo -e "${YELLOW}Checking package contents...${NC}"
npm pack --dry-run

# Ask for confirmation
NEW_VERSION=$(node -p "require('./package.json').version")
read -p "$(echo -e ${YELLOW}Publish @miklermpz/expo-audio-studio@$NEW_VERSION to npm? [y/N]: ${NC})" confirm_publish

if [[ $confirm_publish =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Publishing to npm...${NC}"
    npm publish --access public
    echo -e "${GREEN}Successfully published @miklermpz/expo-audio-studio@$NEW_VERSION!${NC}"
    
    # Optional: commit and tag
    read -p "$(echo -e ${YELLOW}Commit and tag this version? [y/N]: ${NC})" commit_tag
    if [[ $commit_tag =~ ^[Yy]$ ]]; then
        git add package.json
        git commit -m "chore: release @miklermpz/expo-audio-studio@$NEW_VERSION"
        git tag "v$NEW_VERSION"
        echo -e "${GREEN}Committed and tagged v$NEW_VERSION${NC}"
        
        read -p "$(echo -e ${YELLOW}Push to remote? [y/N]: ${NC})" push_remote
        if [[ $push_remote =~ ^[Yy]$ ]]; then
            git push && git push --tags
            echo -e "${GREEN}Pushed to remote${NC}"
        fi
    fi
else
    echo -e "${BLUE}Publication cancelled.${NC}"
fi

echo -e "${GREEN}Done!${NC}"