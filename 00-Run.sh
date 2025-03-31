#!/bin/bash
set -eo pipefail

# === CONFIGURATION ===
COMMENT="add build number"
#
#
GLOBVERS='0.9'
PROJ_NAME="bikelog"
# Paths
OUT_PATH="$HOME"
PROJ_PATH="$OUT_PATH/AndroidStudioProjects/$PROJ_NAME"
APK_PATH="$PROJ_PATH/build/app/outputs/flutter-apk"
ZIP_DIR="$OUT_PATH/ZIP"
PROJ_ZIP_DIR="$ZIP_DIR/$PROJ_NAME"
PUB_FILE="pubspec.yaml"
GLOB_FILE="./lib/globals.dart"

# Flags
SKIP_GIT=false
SKIP_ZIP=false
SKIP_VERSION_UPDATE=false
SKIP_BUILD=false
SHOW_HELP=false

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============ FUNCTIONS ============
show_help() {
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${NC}"
    echo -e "Build script for $PROJ_NAME Flutter project"
    echo -e "\nOptions:"
    echo -e "  -G, --no-git          Skip Git operations (commit and tag)"
    echo -e "  -Z, --no-zip          Skip creating project zip archive"
    echo -e "  -V, --no-version      Skip version increment and update"
    echo -e "  -B, --no-build        Skip the actual build process (for testing)"
    echo -e "  -h, --help            Show this help message"
    echo -e "\nExamples:"
    echo -e "  $0 --no-git           # Build without Git operations"
    echo -e "  $0 --no-version       # Build without updating version numbers"
    echo -e "  $0 --no-build         # Run script without actual build (for testing)"
    exit 0
}

check_dependencies() {
    local missing=()
    for cmd in flutter git sed; do
        if ! command -v "$cmd" &> /dev/null; then
            missing+=("$cmd")
        fi
    done

    if [ ${#missing[@]} -gt 0 ]; then
        echo -e "${RED}✗ Missing dependencies:${NC} ${missing[*]}"
        exit 1
    fi
}

safe_sed() {
    local file=$1
    local pattern=$2
    local replacement=$3
    
    if [ ! -f "$file" ]; then
        echo -e "${RED}✗ File not found:${NC} $file"
        exit 1
    fi

    sed -i "s/$(echo "$pattern" | sed 's/[\/&]/\\&/g')/$(echo "$replacement" | sed 's/[\/&]/\\&/g')/g" "$file"
}

get_current_version() {
    grep -oP 'version: \K[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+' "$PUB_FILE" 2>/dev/null || true
}

auto_increment_version() {
    echo -e "${YELLOW}===== AUTO INCREMENT VERSION =====${NC}"

    # If version update is skipped, just get the current version
    if [ "$SKIP_VERSION_UPDATE" = true ]; then
        CURRENT_VERSION=$(get_current_version)
        if [[ "$CURRENT_VERSION" =~ ([0-9]+\.[0-9]+\.[0-9]+)\+([0-9]+)$ ]]; then
            VER=${BASH_REMATCH[1]}
            VER_CODE=${BASH_REMATCH[2]}
            FULL_VER="$VER+$VER_CODE"
            echo -e "${GREEN}✓ Using existing version: $FULL_VER (version update skipped)${NC}"
        else
            # Fallback if no version found
            VER="${GLOBVERS}.000000"
            VER_CODE=1
            FULL_VER="$VER+$VER_CODE"
            echo -e "${YELLOW}! No existing version found, using default: $FULL_VER${NC}"
        fi
        return
    fi

    # Set version based on date if not specified
    if [ -z "$VER" ]; then
        DATE_SHORT=$(date +"%y%m%d")
        VER="${GLOBVERS}.${DATE_SHORT}"
        echo -e "${GREEN}✓ Version set to $VER based on current date${NC}"
    fi

    # Auto-increment version code if not specified
    if [ -z "$VER_CODE" ]; then
        CURRENT_VERSION=$(get_current_version)
        if [[ "$CURRENT_VERSION" =~ \+([0-9]+)$ ]]; then
            CURRENT_CODE=${BASH_REMATCH[1]}
            VER_CODE=$((CURRENT_CODE + 1))
            echo -e "${GREEN}✓ Version code incremented from $CURRENT_CODE to $VER_CODE${NC}"
        else
            VER_CODE=1
            echo -e "${GREEN}✓ Version code set to $VER_CODE (no previous version found)${NC}"
        fi
    fi

    FULL_VER="$VER+$VER_CODE"
    echo -e "${GREEN}✓ Full version: $FULL_VER${NC}"
}

update_version() {
    if [ "$SKIP_VERSION_UPDATE" = true ]; then
        echo -e "${YELLOW}===== SKIPPING VERSION UPDATE =====${NC}"
        return
    fi

    echo -e "${YELLOW}===== UPDATING VERSION INFORMATION =====${NC}"

    # Update pubspec.yaml
    safe_sed "$PUB_FILE" "version: [0-9]\+\.[0-9]\+\.[0-9]\+.*" "version: $FULL_VER"
    echo -e "${GREEN}✓ Updated $PUB_FILE to version $FULL_VER${NC}"

    # Update globals.dart
    safe_sed "$GLOB_FILE" "const String progVersion = '[0-9]\+\.[0-9]\+\.[0-9]\+'" "const String progVersion = '$VER'"
    echo -e "${GREEN}✓ Updated $GLOB_FILE to version $VER${NC}"

    # Update build number in globals.dart
    safe_sed "$GLOB_FILE" "const int buildNumber = [0-9]\+" "const int buildNumber = $VER_CODE"
    echo -e "${GREEN}✓ Updated build number to $VER_CODE in $GLOB_FILE${NC}"

    # Git operations if not skipped
    if [ "$SKIP_GIT" = false ] && { [ -d ".git" ] || git rev-parse --is-inside-work-tree >/dev/null 2>&1; }; then
        # Explicitly add only the files we want to commit
        git add "$PUB_FILE" "$GLOB_FILE" "$(basename "$0")"
        
        # Check if there are changes to commit
        if git diff --cached --quiet; then
            echo -e "${YELLOW}! No changes to commit for version update${NC}"
        else
            git commit -m "Version bump to $FULL_VER: $COMMENT"
            git tag -a "v$FULL_VER" -m "Release $FULL_VER: $COMMENT"
            echo -e "${GREEN}✓ Created Git commit and tag v$FULL_VER${NC}"
        fi
    elif [ "$SKIP_GIT" = false ]; then
        echo -e "${YELLOW}! Warning: Not a Git repository, skipping version control operations${NC}"
    fi
}

create_archive() {
    if [ "$SKIP_ZIP" = true ]; then
        echo -e "${YELLOW}===== SKIPPING ARCHIVE CREATION =====${NC}"
        return
    fi

    echo -e "${YELLOW}===== CREATING PROJECT ARCHIVE =====${NC}"
    
    mkdir -p "$PROJ_ZIP_DIR"
    local FILE_LIST
    FILE_LIST=$(mktemp)
    trap 'rm -f "$FILE_LIST"' EXIT

    # Add files to archive
    find lib -type f > "$FILE_LIST"
    find assets -type f 2>/dev/null >> "$FILE_LIST"
    find android -type f ! -name "*.apk" >> "$FILE_LIST"
    find .git -type f >> "$FILE_LIST"
    [ -f "$PUB_FILE" ] && echo "$PUB_FILE" >> "$FILE_LIST"
    [ -f ".gitignore" ] && echo ".gitignore" >> "$FILE_LIST"
    echo "$(basename "$0")" >> "$FILE_LIST"

    ZIP_NAME="${PROJ_ZIP_DIR}/${PROJ_NAME}-${VER}-${VER_CODE}-$(date +"%Y%m%d").zip"
    (cd "$PROJ_PATH" && zip -9 -@ "$ZIP_NAME" < "$FILE_LIST")
    
    echo -e "${GREEN}✓ Archive created: $ZIP_NAME${NC}"
}

disable_debug() {
    echo -e "${YELLOW}===== DISABLING DEBUG MODE =====${NC}"
    OLD_DEBUG_VALUE=$(grep -oP 'bool xvDebug\s*=\s*\K[^;]+' "$GLOB_FILE" || true)
    
    if [ -n "$OLD_DEBUG_VALUE" ]; then
        safe_sed "$GLOB_FILE" "bool xvDebug\s*=\s*[^;]*" "bool xvDebug = false"
        echo -e "${GREEN}✓ Debug mode disabled (xvDebug set to false)${NC}"
    else
        echo -e "${YELLOW}! Warning: Could not find xvDebug value in $GLOB_FILE${NC}"
    fi
}

restore_debug() {
    echo -e "${YELLOW}===== RESTORING DEBUG MODE =====${NC}"
    
    if [ -n "$OLD_DEBUG_VALUE" ]; then
        safe_sed "$GLOB_FILE" "bool xvDebug\s*=\s*[^;]*" "bool xvDebug = $OLD_DEBUG_VALUE"
        echo -e "${GREEN}✓ Debug mode restored (xvDebug set to $OLD_DEBUG_VALUE)${NC}"
    fi
}

build_app() {
    if [ "$SKIP_BUILD" = true ]; then
        echo -e "${YELLOW}===== SKIPPING BUILD PROCESS =====${NC}"
        return
    fi

    echo -e "${YELLOW}===== BUILDING APPLICATION =====${NC}"
    echo -e "Building project ${GREEN}$PROJ_NAME${NC} version ${GREEN}$VER+$VER_CODE${NC}"

    flutter pub get
    flutter pub run flutter_launcher_icons
    flutter build apk --release
    flutter build apk --release --split-per-abi

    # Rename APK files
    rename_apk() {
        local src=$1
        local arch=$2
        if [ -f "$src" ]; then
            local dest="$APK_PATH/app-${arch}-release-${VER}-${VER_CODE}.apk"
            mv "$src" "$dest"
            echo -e "${GREEN}✓ Created: $dest${NC}"
        fi
    }

    rename_apk "$APK_PATH/app-release.apk" "universal"
    rename_apk "$APK_PATH/app-arm64-v8a-release.apk" "arm64-v8a"
    rename_apk "$APK_PATH/app-armeabi-v7a-release.apk" "armeabi-v7a"
    rename_apk "$APK_PATH/app-x86_64-release.apk" "x86_64"
}

clean_output() {
    if [ "$SKIP_BUILD" = true ]; then
        return
    fi

    echo -e "${YELLOW}===== CLEANING OLD APK FILES =====${NC}"
    local OUT_DIR="$PROJ_PATH/build/app/outputs"
    
    rm -f "$OUT_DIR/apk/debug/"*.apk 2>/dev/null || true
    rm -f "$OUT_DIR/apk/release/"*.apk 2>/dev/null || true
    rm -f "$OUT_DIR/flutter-apk/"*v7a*.* 2>/dev/null || true
    rm -f "$OUT_DIR/flutter-apk/"*x86*.* 2>/dev/null || true
    rm -f "$OUT_DIR/flutter-apk/"*debug*.* 2>/dev/null || true
    rm -f "$OUT_DIR/flutter-apk/"*.sha1 2>/dev/null || true
    
    echo -e "${GREEN}✓ Cleaned old build files${NC}"
}

copy_final_apk() {
    if [ "$SKIP_BUILD" = true ]; then
        return
    fi

    echo -e "${YELLOW}===== COPYING FINAL APK =====${NC}"
    local SRC="$APK_PATH/app-arm64-v8a-release-$VER-$VER_CODE.apk"
    
    if [ ! -f "$SRC" ]; then
        echo -e "${RED}✗ No arm64 APK found to copy for version $VER-$VER_CODE${NC}"
        return 1
    fi

    local DEST="$PROJ_PATH/${PROJ_NAME^}-$VER_CODE.apkx"
    local APK_ARCHIVE="$PROJ_ZIP_DIR/${PROJ_NAME^}-$VER-$VER_CODE-$(date +"%Y%m%d").apk"
    
    cp -f "$SRC" "$DEST"
    cp -f "$SRC" "$APK_ARCHIVE"
    
    echo -e "${GREEN}✓ Copied final APK to: $DEST${NC}"
    echo -e "${GREEN}✓ Archived APK to: $APK_ARCHIVE${NC}"
}

# ============ MAIN EXECUTION ============
# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -G|--no-git) SKIP_GIT=true ;;
        -Z|--no-zip) SKIP_ZIP=true ;;
        -V|--no-version) SKIP_VERSION_UPDATE=true ;;
        -B|--no-build) SKIP_BUILD=true ;;
        -h|--help) SHOW_HELP=true ;;
        *) echo -e "${RED}Unknown option: $1${NC}"; exit 1 ;;
    esac
    shift
done

if [ "$SHOW_HELP" = true ]; then
    show_help
fi

echo -e "${YELLOW}========== STARTING BUILD PROCESS ==========${NC}"
echo -e "Project: ${GREEN}$PROJ_NAME${NC}"

check_dependencies
auto_increment_version

echo -e "Version: ${GREEN}$FULL_VER${NC}"
echo -e "Date: ${GREEN}$(date +"%Y-%m-%d %H:%M:%S")${NC}"
echo -e "${YELLOW}==========================================${NC}"

# Execute build steps
update_version
create_archive
disable_debug
build_app
restore_debug
clean_output
copy_final_apk

echo -e "${YELLOW}========== BUILD PROCESS COMPLETED ==========${NC}"
