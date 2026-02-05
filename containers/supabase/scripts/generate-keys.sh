#!/usr/bin/env bash
#
# Generate JWT keys (ANON_KEY and SERVICE_ROLE_KEY) from a JWT secret
# Usage: ./generate-keys.sh <jwt_secret>
#

set -e

JWT_SECRET="${1:-}"

if [ -z "$JWT_SECRET" ]; then
    echo "Usage: $0 <jwt_secret>"
    echo ""
    echo "Generate a JWT secret first with:"
    echo "  openssl rand -base64 32"
    exit 1
fi

# Check for required tools
if ! command -v openssl &> /dev/null; then
    echo "Error: openssl is required but not installed"
    exit 1
fi

# Base64 URL encode (no padding)
base64url_encode() {
    openssl base64 -e -A | tr '+/' '-_' | tr -d '='
}

# Create JWT
create_jwt() {
    local role="$1"
    local exp="$2"

    # Header
    local header='{"alg":"HS256","typ":"JWT"}'
    local header_base64=$(echo -n "$header" | base64url_encode)

    # Payload
    local payload="{\"iss\":\"supabase\",\"role\":\"${role}\",\"iat\":$(date +%s),\"exp\":${exp}}"
    local payload_base64=$(echo -n "$payload" | base64url_encode)

    # Signature
    local signature=$(echo -n "${header_base64}.${payload_base64}" | openssl dgst -sha256 -hmac "$JWT_SECRET" -binary | base64url_encode)

    echo "${header_base64}.${payload_base64}.${signature}"
}

# Expiry: 10 years from now
EXPIRY=$(($(date +%s) + 315360000))

ANON_KEY=$(create_jwt "anon" "$EXPIRY")
SERVICE_ROLE_KEY=$(create_jwt "service_role" "$EXPIRY")

echo "ANON_KEY=${ANON_KEY}"
echo ""
echo "SERVICE_ROLE_KEY=${SERVICE_ROLE_KEY}"
