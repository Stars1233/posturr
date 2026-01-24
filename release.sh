#!/bin/bash

# Posturr Release Script
# Creates a new release with build, DMG, and GitHub release

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# Check for required dependencies
check_dependency() {
    local cmd="$1"
    local install_cmd="$2"
    local description="$3"

    if ! command -v "$cmd" &> /dev/null; then
        echo -e "${RED}Error: $cmd is not installed${NC}"
        echo -e "$description"
        echo ""
        echo -e "Install with: ${CYAN}$install_cmd${NC}"
        echo ""
        echo -n "Would you like to install it now? (y/N): "
        read INSTALL
        if [ "$INSTALL" = "y" ] || [ "$INSTALL" = "Y" ]; then
            eval "$install_cmd"
            if ! command -v "$cmd" &> /dev/null; then
                echo -e "${RED}Installation failed. Please install manually.${NC}"
                exit 1
            fi
            echo -e "${GREEN}$cmd installed successfully${NC}"
        else
            exit 1
        fi
    fi
}

# Check Xcode Command Line Tools (for swiftc)
if ! command -v swiftc &> /dev/null; then
    echo -e "${RED}Error: Xcode Command Line Tools not installed${NC}"
    echo -e "Required for compiling Swift code"
    echo ""
    echo -e "Install with: ${CYAN}xcode-select --install${NC}"
    exit 1
fi

# Check for Homebrew
if ! command -v brew &> /dev/null; then
    echo -e "${RED}Error: Homebrew is not installed${NC}"
    echo -e "Required for installing dependencies"
    echo ""
    echo -e "Install with: ${CYAN}/bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\"${NC}"
    exit 1
fi

# Check for create-dmg
check_dependency "create-dmg" "brew install create-dmg" "Required for creating DMG installer"

# Check for gh (GitHub CLI)
check_dependency "gh" "brew install gh" "Required for creating GitHub releases"

# Check if gh is authenticated
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}GitHub CLI is not authenticated${NC}"
    echo -n "Would you like to authenticate now? (y/N): "
    read AUTH
    if [ "$AUTH" = "y" ] || [ "$AUTH" = "Y" ]; then
        gh auth login
    else
        echo -e "${YELLOW}Skipping GitHub release creation${NC}"
        SKIP_GH_RELEASE=true
    fi
fi

# Check for git
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: git is not installed${NC}"
    exit 1
fi

# Get version from argument or prompt
VERSION="${1:-}"
if [ -z "$VERSION" ]; then
    echo -n "Enter version (e.g., 1.0.1): "
    read VERSION
fi

# Validate version format
if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9]+)?$ ]]; then
    echo -e "${RED}Invalid version format. Use: X.Y.Z or X.Y.Z-suffix${NC}"
    exit 1
fi

TAG="v$VERSION"
ZIP_NAME="Posturr-$TAG.zip"
DMG_NAME="Posturr-$TAG.dmg"

echo ""
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo -e "${CYAN}  Posturr Release Script - $TAG${NC}"
echo -e "${CYAN}═══════════════════════════════════════${NC}"
echo ""

# Check for uncommitted changes
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${YELLOW}Warning: You have uncommitted changes${NC}"
    echo -n "Continue anyway? (y/N): "
    read CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
        exit 1
    fi
fi

# Check if tag already exists
if git rev-parse "$TAG" >/dev/null 2>&1; then
    echo -e "${YELLOW}Tag $TAG already exists${NC}"
    echo -n "Delete and recreate? (y/N): "
    read DELETE_TAG
    if [ "$DELETE_TAG" = "y" ] || [ "$DELETE_TAG" = "Y" ]; then
        git tag -d "$TAG" 2>/dev/null || true
        git push origin ":refs/tags/$TAG" 2>/dev/null || true
    else
        exit 1
    fi
fi

# Step 1: Build
echo -e "${GREEN}[1/5] Building app...${NC}"
./build.sh --release

# Step 2: Create DMG
echo -e "${GREEN}[2/5] Creating DMG...${NC}"
hdiutil detach /Volumes/Posturr 2>/dev/null || true
rm -f "build/$DMG_NAME"

create-dmg \
    --volname "Posturr" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "Posturr.app" 150 190 \
    --app-drop-link 450 190 \
    "build/$DMG_NAME" \
    build/Posturr.app

# Create zip with correct version name
rm -f "build/$ZIP_NAME"
cd build && zip -r "$ZIP_NAME" Posturr.app && cd ..

# Step 3: Create git tag
echo -e "${GREEN}[3/5] Creating git tag...${NC}"
git tag "$TAG"
git push origin "$TAG"

# Step 4: Create GitHub release
echo -e "${GREEN}[4/5] Creating GitHub release...${NC}"

RELEASE_NOTES="## Posturr $TAG

A macOS app that blurs your screen when you slouch.

### Features
- Real-time posture monitoring using Vision framework
- Multi-screen corner calibration for personalized detection
- Progressive blur that eases in gently
- Adjustable sensitivity and dead zone
- Universal binary (Apple Silicon + Intel)

### Installation

1. Download the \`.dmg\` or \`.zip\`
2. Drag \`Posturr.app\` to Applications
3. **First launch**: Right-click → Open → Click \"Open\"
4. Grant camera permission, then complete calibration
5. Look at each corner and press Space

### Requirements
- macOS 13.0 (Ventura) or later"

if [ "$SKIP_GH_RELEASE" = "true" ]; then
    echo -e "${YELLOW}[5/5] Skipping GitHub release (not authenticated)${NC}"
    echo ""
    echo "To create the release manually, run:"
    echo -e "${CYAN}gh auth login${NC}"
    echo -e "${CYAN}gh release create $TAG build/$ZIP_NAME build/$DMG_NAME --title \"Posturr $TAG\"${NC}"
else
    # Delete existing release if present
    gh release delete "$TAG" --yes 2>/dev/null || true

    # Create release
    gh release create "$TAG" \
        "build/$ZIP_NAME" \
        "build/$DMG_NAME" \
        --title "Posturr $TAG" \
        --notes "$RELEASE_NOTES"

    echo -e "${GREEN}[5/5] Release created!${NC}"
fi

echo ""
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo -e "${GREEN}  Release $TAG complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════${NC}"
echo ""
echo "Files:"
ls -lh "build/$ZIP_NAME" "build/$DMG_NAME" 2>/dev/null
echo ""
echo -e "Release URL: ${CYAN}https://github.com/tldev/posturr/releases/tag/$TAG${NC}"
