#!/usr/bin/env python
"""
Test script to verify MinIO static storage configuration in Django.
This file should be placed in your Django project root and run with:
python minio_test.py
"""

import os
import sys
import django
from django.conf import settings
from django.core.management import call_command
import io
import uuid

# Set up Django environment
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'core.settings')
django.setup()

def test_minio_connection():
    """Test the MinIO connection and configuration"""
    print("\n=== Testing MinIO Storage Configuration ===\n")
    
    # Print the current storage settings
    print(f"STATICFILES_STORAGE: {settings.STATICFILES_STORAGE}")
    print(f"DEFAULT_FILE_STORAGE: {settings.DEFAULT_FILE_STORAGE}")
    print(f"STATIC_URL: {settings.STATIC_URL}")
    print(f"MEDIA_URL: {settings.MEDIA_URL}")
    print(f"MinIO Endpoint: {settings.MINIO_STORAGE_ENDPOINT}")
    print(f"MinIO Static Bucket: {settings.MINIO_STORAGE_STATIC_BUCKET_NAME}")
    
    # Test if we can get the storage instance
    from django.contrib.staticfiles.storage import staticfiles_storage
    from django.core.files.storage import default_storage
    
    print("\n--- Testing Static Files Storage ---")
    try:
        print(f"Storage class: {staticfiles_storage.__class__.__name__}")
        print("Attempting to list files in static bucket...")
        
        # Try to list some files
        static_files = list(staticfiles_storage.listdir(""))
        print(f"Found directories: {static_files[0]}")
        print(f"Found files: {len(static_files[1])} files")
        
        # Check a specific file if any exist
        if static_files[1]:
            test_file = static_files[1][0]
            print(f"Testing URL for: {test_file}")
            url = staticfiles_storage.url(test_file)
            print(f"URL: {url}")
        
        print("✅ Static files storage is working correctly")
    except Exception as e:
        print(f"❌ Error with static files storage: {str(e)}")
    
    print("\n--- Testing Media Files Storage ---")
    try:
        print(f"Storage class: {default_storage.__class__.__name__}")
        
        # Create a test file
        test_filename = f"test-{uuid.uuid4()}.txt"
        content = "This is a test file to verify MinIO media storage"
        
        print(f"Creating test file: {test_filename}")
        
        # Save the file to storage
        file = io.BytesIO(content.encode())
        path = default_storage.save(test_filename, file)
        
        # Get the URL
        url = default_storage.url(path)
        print(f"File saved at: {path}")
        print(f"File URL: {url}")
        
        # Check if the file exists
        exists = default_storage.exists(path)
        print(f"File exists in storage: {exists}")
        
        # Cleanup - delete the test file
        default_storage.delete(path)
        print(f"Test file deleted")
        
        print("✅ Media files storage is working correctly")
    except Exception as e:
        print(f"❌ Error with media files storage: {str(e)}")
    
    print("\n--- Testing collectstatic ---")
    try:
        # Redirect stdout to capture output
        old_stdout = sys.stdout
        redirected_output = io.StringIO()
        sys.stdout = redirected_output
        
        # Run collectstatic with --no-input flag
        call_command("collectstatic", interactive=False, verbosity=0)
        
        # Restore stdout
        sys.stdout = old_stdout
        
        print("collectstatic completed successfully")
        print("✅ Static files collected to MinIO storage")
    except Exception as e:
        # Restore stdout
        sys.stdout = old_stdout
        print(f"❌ Error running collectstatic: {str(e)}")
    
    print("\n=== MinIO Storage Test Complete ===")

if __name__ == "__main__":
    test_minio_connection()