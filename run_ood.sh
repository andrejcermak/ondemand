#!/bin/bash

# Function to display usage
usage() {
    echo "Usage: $0 <server_name> <oidc_client_id> <oidc_client_secret> [oidc_provider_metadata_url]"
    echo "Example: $0 localhost 'client-id' 'client-secret' 'https://accounts.google.com/.well-known/openid-configuration'"
    exit 1
}

# Check if required arguments are provided
if [ $# -lt 3 ]; then
    echo "Error: Missing required arguments"
    usage
fi

# Read arguments
SERVERNAME="$1"
OIDC_CLIENT_ID="$2"
OIDC_CLIENT_SECRET="$3"
OIDC_PROVIDER_METADATA_URL="${4:-https://accounts.google.com/.well-known/openid-configuration}"

echo "Generating configuration..."
echo "Server Name: $SERVERNAME"
echo "OIDC Client ID: $OIDC_CLIENT_ID"
echo "OIDC Provider: $OIDC_PROVIDER_METADATA_URL"

# Create the config directory if it doesn't exist
mkdir -p ./config

# Generate the ood_portal.yml file
cat > ./config/ood_portal.yml << EOF
---
servername: '${SERVERNAME}'
auth:
  - 'AuthType openid-connect'
  - 'Require valid-user'
oidc_uri: "/oidc/redirect_uri"
oidc_provider_metadata_url: "${OIDC_PROVIDER_METADATA_URL}"
oidc_client_id: '${OIDC_CLIENT_ID}'
oidc_client_secret: '${OIDC_CLIENT_SECRET}'
oidc_remote_user_claim: "email"
oidc_scope: "openid profile email"
oidc_session_inactivity_timeout: 28800
oidc_session_max_duration: 28800
oidc_state_max_number_of_cookies: "10 true"
oidc_settings:
  OIDCPassIDTokenAs: "serialized"
  OIDCPassRefreshToken: "On"
  OIDCPassClaimsAs: "environment"
  OIDCStripCookies: "mod_auth_openidc_session mod_auth_openidc_session_chunks mod_auth_open"
  OIDCResponseType: "code"
OIDCRedirectURI: 'http://${SERVERNAME}/oidc/redirect_uri'
user_map_match: '^([^@]+)@'
EOF

echo "Configuration file generated at ./config/ood_portal.yml"

# Build the Docker image (if not already built)
echo "Building Docker image..."
docker build -t ondemand-oidc . 2>/dev/null || {
    echo "Docker image already exists or build failed"
}

# Stop and remove existing container
echo "Stopping existing container..."
docker stop ondemand-oidc 2>/dev/null
docker rm ondemand-oidc 2>/dev/null

# Run the container with the generated config
echo "Starting OnDemand container..."
docker run -d \
  --name ondemand-oidc \
  -p 80:80 \
  -p 443:443 \
  -v "$(pwd)/config/ood_portal.yml:/etc/ood/config/ood_portal.yml:ro" \
  ondemand-oidc

echo "Container started! Check status with: docker ps"
echo "View logs with: docker logs ondemand-oidc"
echo "Access application at: http://$SERVERNAME"
