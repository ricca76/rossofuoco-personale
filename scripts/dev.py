#!/usr/bin/env python3
"""
RossoFuoco Mobile - Cross-Platform Developer Automation Runner
Supports Android (Kotlin/Compose) & iOS (Swift/SwiftUI/XcodeGen/Fastlane)
"""

import sys
import os
import shutil
import subprocess

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

def run_cmd(cmd, cwd=ROOT_DIR, check=True):
    print(f"\n🚀 Running: {' '.join(cmd) if isinstance(cmd, list) else cmd}")
    res = subprocess.run(cmd, cwd=cwd, shell=isinstance(cmd, str))
    if check and res.returncode != 0:
        print(f"❌ Command failed with return code {res.returncode}")
        sys.exit(res.returncode)
    return res

def check_env():
    print("=" * 65)
    print("🔍 Environment & Tooling Health Check")
    print("=" * 65)
    
    tools = [
        ("Java (JDK)", ["java", "-version"]),
        ("Gradle", ["gradle", "-v"]),
        ("Python 3", [sys.executable, "--version"]),
        ("Git", ["git", "--version"]),
        ("Xcode (macOS)", ["xcodebuild", "-version"]),
        ("XcodeGen", ["xcodegen", "--version"]),
        ("Fastlane", ["fastlane", "--version"])
    ]
    
    for name, cmd in tools:
        executable = shutil.which(cmd[0])
        if executable:
            print(f"  ✅ {name:<18} : Found ({executable})")
        else:
            print(f"  ⚠️  {name:<18} : Not found in PATH")
    print("\n✅ Health check complete.")

def build_android():
    print("=" * 65)
    print("🤖 Building Android Artifacts (Debug, Release APK & AAB)")
    print("=" * 65)
    run_cmd(["gradle", ":app:assembleDebug", ":app:assembleRelease", ":app:bundleRelease", "--stacktrace"])
    print("\n✅ Android build succeeded!")
    print("Artifacts generated:")
    print("  - Debug APK:   app/build/outputs/apk/debug/app-debug.apk")
    print("  - Release APK: app/build/outputs/apk/release/app-release-unsigned.apk")
    print("  - Release AAB: app/build/outputs/bundle/release/app-release.aab")

def test_android():
    print("=" * 65)
    print("🧪 Running Android Unit Tests")
    print("=" * 65)
    run_cmd(["gradle", ":app:testDebugUnitTest", "--stacktrace"])
    print("\n✅ All unit tests passed!")

def generate_ios():
    print("=" * 65)
    print("🍎 Generating Xcode Project from project.yml (XcodeGen)")
    print("=" * 65)
    if not shutil.which("xcodegen"):
        print("❌ XcodeGen not found. Please install via 'brew install xcodegen' on macOS.")
        sys.exit(1)
    run_cmd(["xcodegen", "generate"])
    print("\n✅ 'RossoFuoco.xcodeproj' generated successfully!")

def validate_assets():
    print("=" * 65)
    print("🎨 Validating Store Assets and Metadata")
    print("=" * 65)
    script = os.path.join(ROOT_DIR, "scripts", "setup_store_metadata.py")
    run_cmd([sys.executable, script])
    print("\n✅ All store graphics and metadata synchronized!")

def show_help():
    print("""
RossoFuoco Mobile Dev CLI

Usage: python3 scripts/dev.py <command>

Available commands:
  check            Check all required tools and compilers
  build-android    Compile Android Debug, Release APK and AAB
  test-android     Run unit tests with Gradle
  generate-ios     Generate Xcode project using XcodeGen
  validate-assets  Validate and organize App Store and Google Play metadata
  help             Show this help screen
""")

def main():
    if len(sys.argv) < 2:
        show_help()
        return

    cmd = sys.argv[1].lower()
    if cmd == "check":
        check_env()
    elif cmd == "build-android":
        build_android()
    elif cmd == "test-android":
        test_android()
    elif cmd == "generate-ios":
        generate_ios()
    elif cmd == "validate-assets":
        validate_assets()
    else:
        show_help()

if __name__ == "__main__":
    main()
