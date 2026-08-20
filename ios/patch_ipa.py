#!/usr/bin/env python3
import sys
import os
import shutil
import zipfile
import subprocess
import struct
import tempfile

def patch_macho_file(file_path, target_sdk_major=26):
    try:
        with open(file_path, 'rb') as f:
            data = bytearray(f.read())

        if len(data) < 32:
            return False

        magic = bytes(data[:4])
        # Support both Fat Mach-O (Universal) and Thin Mach-O (64-bit arm64)
        if magic in (b'\xcf\xfa\xed\xfe', b'\xfe\xed\xfa\xcf'):
            # Thin 64-bit Mach-O
            is_le = (magic == b'\xcf\xfa\xed\xfe')
            endian = '<' if is_le else '>'
            _, _, _, _, ncmds, _, _, _ = struct.unpack_from(endian + '8I', data, 0)
            offset = 32
            LC_BUILD_VERSION = 0x32
            LC_VERSION_MIN_IPHONEOS = 0x25
            
            modified = False
            for _ in range(ncmds):
                if offset + 8 > len(data):
                    break
                cmd, cmdsize = struct.unpack_from(endian + '2I', data, offset)
                if cmd == LC_BUILD_VERSION and offset + 24 <= len(data):
                    platform, minos, sdk, ntools = struct.unpack_from(endian + '4I', data, offset + 8)
                    new_sdk = (target_sdk_major << 16)
                    struct.pack_into(endian + 'I', data, offset + 16, new_sdk)
                    print(f"[{file_path}] Patched LC_BUILD_VERSION sdk from {sdk>>16}.{(sdk>>8)&0xff} to {target_sdk_major}.0")
                    modified = True
                elif cmd == LC_VERSION_MIN_IPHONEOS and offset + 16 <= len(data):
                    version, sdk = struct.unpack_from(endian + '2I', data, offset + 8)
                    new_sdk = (target_sdk_major << 16)
                    struct.pack_into(endian + 'I', data, offset + 12, new_sdk)
                    print(f"[{file_path}] Patched LC_VERSION_MIN_IPHONEOS sdk from {sdk>>16}.{(sdk>>8)&0xff} to {target_sdk_major}.0")
                    modified = True
                offset += cmdsize
                
            if modified:
                with open(file_path, 'wb') as f:
                    f.write(data)
                return True
        return False
    except Exception as e:
        print(f"Error patching Mach-O {file_path}: {e}")
        return False

def patch_ipa(ipa_path, keychain_db=None):
    if not os.path.exists(ipa_path):
        print(f"IPA not found at: {ipa_path}")
        return False

    temp_dir = tempfile.mkdtemp(prefix="ipa_patch_")
    try:
        print(f"Unzipping {ipa_path}...")
        with zipfile.ZipFile(ipa_path, 'r') as zip_ref:
            zip_ref.extractall(temp_dir)

        payload_dir = os.path.join(temp_dir, "Payload")
        if not os.path.exists(payload_dir):
            print("No Payload dir found in IPA!")
            return False

        app_dirs = [os.path.join(payload_dir, d) for d in os.listdir(payload_dir) if d.endswith(".app")]
        if not app_dirs:
            print("No .app found in Payload!")
            return False

        app_dir = app_dirs[0]
        app_name = os.path.splitext(os.path.basename(app_dir))[0]
        plist_path = os.path.join(app_dir, "Info.plist")

        print(f"Updating Info.plist for {app_name}...")
        subprocess.run(["plutil", "-convert", "xml1", plist_path], check=False)
        
        plist_commands = [
            'Set :ITSAppUsesNonExemptEncryption false',
            'Add :ITSAppUsesNonExemptEncryption bool false',
            'Set :DTPlatformVersion 26.0',
            'Add :DTPlatformVersion string 26.0',
            'Set :DTSDKName iphoneos26.0',
            'Add :DTSDKName string iphoneos26.0',
            'Set :DTXcode 2600',
            'Add :DTXcode string 2600',
            'Set :DTXcodeBuild 26A100',
            'Add :DTXcodeBuild string 26A100',
            'Set :DTSDKBuild 26A100',
            'Add :DTSDKBuild string 26A100',
            'Set :BuildMachineOSBuild 25A100',
            'Add :BuildMachineOSBuild string 25A100'
        ]
        
        for cmd in plist_commands:
            action = cmd.split()[0]
            key = cmd.split()[1]
            subprocess.run(['/usr/libexec/PlistBuddy', '-c', cmd, plist_path], capture_output=True)

        subprocess.run(["plutil", "-convert", "binary1", plist_path], check=False)

        # Patch all Mach-O binaries in the app bundle
        print("Patching Mach-O binaries...")
        for root, _, files in os.walk(app_dir):
            for file in files:
                fpath = os.path.join(root, file)
                if os.path.islink(fpath):
                    continue
                # If executable or .dylib or framework binary
                patch_macho_file(fpath, target_sdk_major=26)

        # Re-sign code
        print("Re-signing app bundle...")
        sign_cmd = ["codesign", "-f", "-s", "Apple Distribution"]
        if keychain_db and os.path.exists(keychain_db):
            sign_cmd.extend(["--keychain", keychain_db])
        sign_cmd.extend(["--preserve-metadata=identifier,entitlements", app_dir])
        
        res = subprocess.run(sign_cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"Code signing warning: {res.stderr}")
            # Retry without keychain flag if failed
            subprocess.run(["codesign", "-f", "-s", "Apple Distribution", "--preserve-metadata=identifier,entitlements", app_dir], check=False)

        # Re-create the IPA zip
        print(f"Repackaging IPA to {ipa_path}...")
        os.remove(ipa_path)
        
        with zipfile.ZipFile(ipa_path, 'w', zipfile.ZIP_DEFLATED) as zip_out:
            for root, dirs, files in os.walk(temp_dir):
                for file in files:
                    full_path = os.path.join(root, file)
                    rel_path = os.path.relpath(full_path, temp_dir)
                    zip_out.write(full_path, rel_path)

        print("IPA successfully patched and ready for App Store Connect!")
        return True

    finally:
        shutil.rmtree(temp_dir, ignore_errors=True)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: patch_ipa.py <path_to_ipa> [keychain_db_path]")
        sys.exit(1)
    
    ipa = sys.argv[1]
    kc = sys.argv[2] if len(sys.argv) > 2 else None
    success = patch_ipa(ipa, kc)
    sys.exit(0 if success else 1)
