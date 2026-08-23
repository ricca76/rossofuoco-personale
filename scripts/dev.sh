#!/usr/bin/env bash
# ==============================================================================
# RossoFuoco Mobile - Unified Developer Automation CLI
# Supports Android (Kotlin/Compose) & iOS (Swift/SwiftUI/XcodeGen/Fastlane)
# ==============================================================================

set -e

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

cd "${ROOT_DIR}"

print_header() {
    echo -e "${PURPLE}==============================================================================${NC}"
    echo -e "${CYAN}  RossoFuoco Personale - Mobile Dev & Automation CLI${NC}"
    echo -e "${PURPLE}==============================================================================${NC}"
}

print_success() {
    echo -e "${GREEN}✔ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✖ $1${NC}"
}

cmd_check() {
    print_header
    print_info "Checking local development environment dependencies..."
    echo ""

    # Check Java / JDK
    if command -v java &> /dev/null; then
        JAVA_VER=$(java -version 2>&1 | head -n 1)
        print_success "Java: ${JAVA_VER}"
    else
        print_error "Java: Not found (Install JDK 17+ for Android development)"
    fi

    # Check Gradle
    if command -v gradle &> /dev/null; then
        GRADLE_VER=$(gradle -v | grep "Gradle " || echo "Installed")
        print_success "Gradle: ${GRADLE_VER}"
    else
        print_warning "Gradle: Not in PATH (using container or wrapper)"
    fi

    # Check Python
    if command -v python3 &> /dev/null; then
        PYTHON_VER=$(python3 --version)
        print_success "Python: ${PYTHON_VER}"
    else
        print_error "Python 3: Not found"
    fi

    # Check Xcode (macOS only)
    if command -v xcodebuild &> /dev/null; then
        XCODE_VER=$(xcodebuild -version | head -n 1)
        print_success "Xcode: ${XCODE_VER}"
    else
        print_info "Xcode: Not present (Required on macOS for iOS builds)"
    fi

    # Check XcodeGen
    if command -v xcodegen &> /dev/null; then
        XCODEGEN_VER=$(xcodegen --version || echo "Installed")
        print_success "XcodeGen: ${XCODEGEN_VER}"
    else
        print_info "XcodeGen: Not present (Install with 'brew install xcodegen' on macOS)"
    fi

    # Check Fastlane
    if command -v fastlane &> /dev/null; then
        FASTLANE_VER=$(fastlane --version | head -n 1 || echo "Installed")
        print_success "Fastlane: ${FASTLANE_VER}"
    else
        print_info "Fastlane: Not present (Install with 'gem install fastlane' for iOS deploys)"
    fi

    # Check Git
    if command -v git &> /dev/null; then
        GIT_VER=$(git --version)
        print_success "Git: ${GIT_VER}"
    else
        print_error "Git: Not found"
    fi

    echo ""
    print_success "Environment check completed!"
}

cmd_build_android() {
    print_header
    print_info "Building Android Debug and Release artifacts..."
    
    gradle :app:assembleDebug :app:assembleRelease :app:bundleRelease --stacktrace
    
    print_success "Android Build complete!"
    echo "Outputs generated:"
    echo "  - Debug APK:   app/build/outputs/apk/debug/app-debug.apk"
    echo "  - Release APK: app/build/outputs/apk/release/app-release-unsigned.apk"
    echo "  - Release AAB: app/build/outputs/bundle/release/app-release.aab"
}

cmd_test_android() {
    print_header
    print_info "Running Android unit tests..."
    gradle :app:testDebugUnitTest --stacktrace
    print_success "Android tests passed successfully!"
}

cmd_generate_ios() {
    print_header
    print_info "Generating Xcode project with XcodeGen..."
    if command -v xcodegen &> /dev/null; then
        xcodegen generate
        print_success "Xcode project 'RossoFuoco.xcodeproj' generated successfully!"
    else
        print_error "XcodeGen is not installed. Run 'brew install xcodegen' on macOS."
    fi
}

cmd_validate_assets() {
    print_header
    print_info "Validating store graphics and metadata..."
    python3 scripts/setup_store_metadata.py
    print_success "All iOS Fastlane and Android Play Store assets verified!"
}

cmd_help() {
    print_header
    echo "Usage: ./scripts/dev.sh [command]"
    echo ""
    echo "Commands:"
    echo "  check            Verify all installed developer tools and dependencies"
    echo "  build-android    Build Android Debug & Release APKs and Release AAB bundle"
    echo "  test-android     Execute Android unit tests with Gradle"
    echo "  generate-ios     Generate native Xcode project (RossoFuoco.xcodeproj) using XcodeGen"
    echo "  validate-assets  Verify and sync all App Store and Play Store graphics & metadata"
    echo "  help             Show this help message"
    echo ""
}

# Command dispatch
case "$1" in
    check)
        cmd_check
        ;;
    build-android)
        cmd_build_android
        ;;
    test-android)
        cmd_test_android
        ;;
    generate-ios)
        cmd_generate_ios
        ;;
    validate-assets)
        cmd_validate_assets
        ;;
    help|"")
        cmd_help
        ;;
    *)
        print_error "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
