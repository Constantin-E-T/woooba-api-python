
import boto3
import requests
from urllib.parse import urlparse
from botocore.client import Config

def test_with_boto3():
    """Test connection using boto3 with different endpoint configurations"""
    
    # Base configuration - Using the API URL instead of UI URL
    base_url = "https://storages3-api.serverplus.org"
    access_key = "vir6ehKJrkhyc9KcNjgI"
    secret_key = "Ov9hnADie8k0XbpPvHNAsEyaItoGgwm87sSorGWz"
    bucket_name = "woooba-static"
    
    print("Testing MinIO connection with boto3 (AWS SDK)")
    
    # Try different endpoint configurations
    endpoint_configs = [
        {
            "url": base_url,
            "description": "Base API URL",
            "addressing_style": "path"
        },
        {
            "url": f"{base_url}/s3",
            "description": "API URL with /s3 path",
            "addressing_style": "path"
        },
        {
            "url": base_url,
            "description": "API URL with virtual addressing",
            "addressing_style": "virtual"
        },
        {
            "url": base_url.replace("//", f"//{bucket_name}."),
            "description": "Virtual host style API URL",
            "addressing_style": "virtual"
        }
    ]
    
    # Try standard S3 endpoint first
    for config in endpoint_configs:
        endpoint_url = config["url"]
        addressing_style = config["addressing_style"]
        desc = config["description"]
        
        print(f"\n---------------------------------------------")
        print(f"Trying {desc}: {endpoint_url}")
        print(f"Using {addressing_style} addressing style")
        
        try:
            session = boto3.session.Session()
            s3 = session.client(
                's3',
                endpoint_url=endpoint_url,
                aws_access_key_id=access_key,
                aws_secret_access_key=secret_key,
                config=Config(
                    signature_version='s3v4',
                    s3={'addressing_style': addressing_style}
                ),
                verify=True
            )
            
            # Test the connection with a simple operation
            print("Checking if bucket exists...")
            try:
                response = s3.head_bucket(Bucket=bucket_name)
                print(f"✓ Successfully connected to bucket '{bucket_name}'")
                
                # Try listing objects
                print("Listing objects...")
                objects = s3.list_objects_v2(Bucket=bucket_name, MaxKeys=5)
                if 'Contents' in objects and objects['Contents']:
                    print(f"✓ Found {len(objects['Contents'])} objects in bucket")
                    for obj in objects['Contents']:
                        print(f"  - {obj['Key']} ({obj['Size']} bytes)")
                else:
                    print("No objects found in bucket")
                    
                # Try upload
                print("Uploading test file...")
                test_content = b"Test file for boto3 connection"
                s3.put_object(
                    Bucket=bucket_name,
                    Key="boto3_test.txt",
                    Body=test_content
                )
                print("✓ File uploaded successfully")
                
                # Delete test file
                print("Deleting test file...")
                s3.delete_object(
                    Bucket=bucket_name,
                    Key="boto3_test.txt"
                )
                print("✓ File deleted successfully")
                
                print("\n✅ CONNECTION SUCCESSFUL!")
                print(f"Working configuration:")
                print(f"  - Endpoint URL: {endpoint_url}")
                print(f"  - Addressing style: {addressing_style}")
                
                # For Django configuration
                parsed_url = urlparse(endpoint_url)
                minio_host = parsed_url.netloc
                print(f"\nRecommended Django configuration:")
                print(f"MINIO_STORAGE_ENDPOINT = '{minio_host}'")
                print(f"MINIO_STORAGE_USE_HTTPS = True")
                if addressing_style == "virtual":
                    print("# You may need to set these additional options:")
                    print("MINIO_STORAGE_MEDIA_URL_ENDPOING = None  # Uses virtual host style")
                    print("MINIO_STORAGE_MEDIA_USE_PRESIGNED = True")
                
                return True
                
            except Exception as e:
                print(f"✗ Operation failed: {e}")
                
        except Exception as e:
            print(f"✗ Connection failed: {e}")
    
    return False

def check_api_health():
    """Check if we can access the API endpoint"""
    url = "https://storages3-api.serverplus.org"
    
    print("\n---------------------------------------------")
    print(f"Checking API endpoint health at: {url}")
    
    try:
        response = requests.head(url, timeout=5)
        print(f"Status code: {response.status_code}")
        
        if response.status_code < 400:  # Any 2xx or 3xx response is considered successful
            print("✓ Successfully reached API endpoint")
            return True
        else:
            print(f"✗ Failed to reach API endpoint: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ Error reaching API endpoint: {e}")
        return False

if __name__ == "__main__":
    print("=================================================")
    print("MinIO Connection Test - Using API Endpoint")
    print("=================================================")
    
    # Check if we can access the API endpoint
    api_accessible = check_api_health()
    
    # Then try S3 API connection
    api_connected = test_with_boto3()
    
    print("\n=================================================")
    print("Test Summary")
    print("=================================================")
    print(f"API endpoint accessible: {'✓' if api_accessible else '✗'}")
    print(f"S3 API connection successful: {'✓' if api_connected else '✗'}")
    
    if not api_connected:
        print("\nRecommendations:")
        print("1. Verify that the API endpoint URL is correct (https://storages3-api.serverplus.org)")
        print("2. Ensure that your access and secret keys are valid and have the necessary permissions")
        print("3. Check if the bucket 'woooba-static' exists and is accessible with your credentials")
        print("4. Verify that the S3 API service is running and properly configured")
        print("5. For Django configuration, you'll need to use the API endpoint URL, not the UI URL")