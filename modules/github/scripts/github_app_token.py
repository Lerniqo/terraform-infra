#!/usr/bin/env python3
"""
GitHub App Token Generator
Generates a JWT token for GitHub App authentication and exchanges it for an access token
"""

import jwt
import time
import json
import sys
import base64
import requests
import argparse

def generate_jwt(app_id, private_key_base64):
    """Generate JWT token for GitHub App"""
    try:
        # Decode the private key
        private_key = base64.b64decode(private_key_base64).decode('utf-8')
        
        # Current time
        now = int(time.time())
        
        # JWT payload
        payload = {
            'iat': now - 10,  # Issued 10 seconds ago to account for clock drift
            'exp': now + 600,  # Expires in 10 minutes
            'iss': int(app_id)
        }
        
        # Generate JWT
        token = jwt.encode(payload, private_key, algorithm='RS256')
        return token
    except Exception as e:
        print(json.dumps({"error": f"JWT generation failed: {str(e)}"}), file=sys.stderr)
        sys.exit(1)

def get_installation_token(jwt_token, installation_id):
    """Exchange JWT for installation access token"""
    try:
        url = f"https://api.github.com/app/installations/{installation_id}/access_tokens"
        headers = {
            "Authorization": f"Bearer {jwt_token}",
            "Accept": "application/vnd.github.v3+json",
            "User-Agent": "Terraform-GitHub-App/1.0"
        }
        
        response = requests.post(url, headers=headers)
        
        if response.status_code == 201:
            return response.json().get('token')
        else:
            error_msg = f"Failed to get installation token: {response.status_code} - {response.text}"
            print(json.dumps({"error": error_msg}), file=sys.stderr)
            return None
    except Exception as e:
        print(json.dumps({"error": f"Installation token request failed: {str(e)}"}), file=sys.stderr)
        return None

def main():
    parser = argparse.ArgumentParser(description='Generate GitHub App access token')
    parser.add_argument('--app-id', required=True, help='GitHub App ID')
    parser.add_argument('--installation-id', required=True, help='GitHub App Installation ID')
    parser.add_argument('--private-key', required=True, help='Base64 encoded private key')
    
    args = parser.parse_args()
    
    # Generate JWT
    jwt_token = generate_jwt(args.app_id, args.private_key)
    
    # Get installation token
    access_token = get_installation_token(jwt_token, args.installation_id)
    
    if access_token:
        print(json.dumps({"token": access_token}))
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()
