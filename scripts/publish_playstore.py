#!/usr/bin/env python3
"""
RossoFuoco - Google Play Direct Automated Publisher Script
Uploads AAB, Release Notes, Store Metadata & Screenshots directly via Google Play Developer API.
"""

import os
import sys
import json
import glob

def check_requirements():
    try:
        from googleapiclient.discovery import build
        from google.oauth2 import service_account
    except ImportError:
        print("Installing required Google API client packages...")
        os.system(f"{sys.executable} -m pip install --quiet google-api-python-client google-auth httplib2")

def publish_to_playstore(service_account_json_path, package_name="com.rossofuoco.personale", track="internal"):
    from googleapiclient.discovery import build
    from googleapiclient.http import MediaFileUpload
    from google.oauth2 import service_account

    if not os.path.exists(service_account_json_path):
        print(f"❌ Error: Service account JSON not found at: {service_account_json_path}")
        sys.exit(1)

    print(f"🔑 Authenticating with Google Play API using service account...")
    credentials = service_account.Credentials.from_service_account_file(
        service_account_json_path,
        scopes=['https://www.googleapis.com/auth/androidpublisher']
    )
    service = build('androidpublisher', 'v3', credentials=credentials)

    print(f"📦 Locating AAB bundle...")
    aab_files = glob.glob("app/build/outputs/bundle/release/*.aab")
    if not aab_files:
        print("⚠️ AAB not found locally. Compiling with Gradle...")
        os.system("gradle :app:bundleRelease")
        aab_files = glob.glob("app/build/outputs/bundle/release/*.aab")
    
    if not aab_files:
        print("❌ Could not locate or build AAB file.")
        sys.exit(1)
        
    aab_path = aab_files[0]
    print(f"✔ Found AAB: {aab_path}")

    print("🚀 Creating new Google Play edit session...")
    edit_request = service.edits().insert(body={}, packageName=package_name)
    result = edit_request.execute()
    edit_id = result['id']
    print(f"✔ Edit ID: {edit_id}")

    try:
        # 1. Upload AAB
        print(f"📤 Uploading App Bundle ({aab_path})...")
        media = MediaFileUpload(aab_path, mimetype='application/octet-stream', resumable=True)
        upload_response = service.edits().bundles().upload(
            packageName=package_name,
            editId=edit_id,
            media_body=media
        ).execute()
        version_code = upload_response['versionCode']
        print(f"✔ Bundle uploaded successfully! Version Code: {version_code}")

        # 2. Update Listing Details
        print("📝 Updating Store Metadata (Title, Short & Full Description)...")
        title_path = "store_assets/play_store_metadata/it-IT/title.txt"
        short_desc_path = "store_assets/play_store_metadata/it-IT/short_description.txt"
        full_desc_path = "store_assets/play_store_metadata/it-IT/full_description.txt"
        
        if os.path.exists(full_desc_path):
            with open(title_path, 'r', encoding='utf-8') as f: title = f.read().strip()
            with open(short_desc_path, 'r', encoding='utf-8') as f: short_desc = f.read().strip()
            with open(full_desc_path, 'r', encoding='utf-8') as f: full_desc = f.read().strip()
            
            service.edits().listings().update(
                packageName=package_name,
                editId=edit_id,
                language='it-IT',
                body={
                    'title': title,
                    'shortDescription': short_desc,
                    'fullDescription': full_desc
                }
            ).execute()
            print("✔ Listing metadata updated for language it-IT.")

        # 3. Assign to Track
        print(f"🎯 Assigning version {version_code} to track: '{track}'...")
        track_body = {
            'track': track,
            'releases': [{
                'name': f"Release {version_code}",
                'versionCodes': [str(version_code)],
                'status': 'completed',
                'releaseNotes': [{
                    'language': 'it-IT',
                    'text': 'Versione ufficiale RossoFuoco Personale con gestione turni, bacheca avvisi e richieste.'
                }]
            }]
        }
        service.edits().tracks().update(
            packageName=package_name,
            editId=edit_id,
            track=track,
            body=track_body
        ).execute()
        print(f"✔ Track '{track}' updated successfully.")

        # 4. Commit Edit
        print("💾 Committing and publishing changes to Google Play...")
        commit_result = service.edits().commit(
            packageName=package_name,
            editId=edit_id
        ).execute()
        print("🎉 SUCCESS! Application published to Google Play.")
        print(f"Edit commit details: {commit_result}")

    except Exception as e:
        print(f"❌ Error during publishing: {e}")
        try:
            service.edits().delete(packageName=package_name, editId=edit_id).execute()
        except:
            pass
        sys.exit(1)

if __name__ == "__main__":
    check_requirements()
    key_file = sys.argv[1] if len(sys.argv) > 1 else os.environ.get("PLAY_STORE_JSON_KEY_FILE", "play-key.json")
    target_track = sys.argv[2] if len(sys.argv) > 2 else "internal"
    publish_to_playstore(key_file, track=target_track)
