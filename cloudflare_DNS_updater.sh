#!/bin/bash

# Cloudflare Dynamic DNS Updater
# Author: tinkermesomething
# Version: 1.1.0
#
# This script updates my DNS A and a specific TXT record on CloudFlare for my self hosted server since my ISP doesn't give static IP for free. 
# It is designed to first check if the external IP matches the current A record, and the proceeds the change if needed. 
# This is so that it only makes API calls as needed.  
# To find the records IDs, I had to use the API to query my DNS entries as it's not info that is not found on the CloudFlare dashboard.

set -euo pipefail

# Configuration
CLOUDFLARE_API_KEY="API KEY"
CLOUDFLARE_ZONE_ID="CloudFlare ZONE ID"
CLOUDFLARE_A_RECORD_ID="Specific A record ID"
CLOUDFLARE_TXT_RECORD_ID="Specific TXT record ID"
CLOUDFLARE_A_RECORD_WEBSITE="mail.example.com"
LOG_FILE="/var/log/cloudflare-dns-update.log"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Get current external IP
NEW_IP=$(curl -s -X GET https://checkip.amazonaws.com)

if [ -z "$NEW_IP" ]; then
    log_message "Error: Failed to retrieve current external IP"
    exit 1
fi

log_message "Current external IP: $NEW_IP"

# Get current A record IP address
CURRENT_A_RECORD_IP=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$CLOUDFLARE_A_RECORD_ID" \
-H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
-H "Content-Type: application/json" | jq -r '.result.content')

if [ -z "$CURRENT_A_RECORD_IP" ]; then
    log_message "Error: Failed to retrieve current A record IP"
    exit 1
fi

# This is the cool part where the script will compare the current external IP with the A record you want updated. 
# Check if IP needs to be updated
if [ "$NEW_IP" != "$CURRENT_A_RECORD_IP" ]; then
    log_message "IP change detected. Updating DNS records..."

    # Update A record
    A_RECORD_UPDATE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$CLOUDFLARE_A_RECORD_ID" \
    -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'"$CLOUDFLARE_A_RECORD_WEBSITE"'","content":"'"$NEW_IP"'","ttl":1,"proxied":false}')

    if echo "$A_RECORD_UPDATE" | jq -e '.success' > /dev/null; then
        log_message "A record updated successfully"
    else
        log_message "Error: Failed to update A record"
        log_message "Error details: $(echo "$A_RECORD_UPDATE" | jq -r '.errors[]')"
    fi

    # Update TXT record
    TXT_RECORD_UPDATE=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$CLOUDFLARE_TXT_RECORD_ID" \
    -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" \
    --data '{"type":"TXT","name":"'"$CLOUDFLARE_A_RECORD_WEBSITE"'","content":"v=spf1 ip4:'"$NEW_IP"' -all","ttl":1}')

    if echo "$TXT_RECORD_UPDATE" | jq -e '.success' > /dev/null; then
        log_message "TXT record updated successfully"
    else
        log_message "Error: Failed to update TXT record"
        log_message "Error details: $(echo "$TXT_RECORD_UPDATE" | jq -r '.errors[]')"
    fi

    log_message "New external IP: $NEW_IP"
else
    log_message "IP is up-to-date. No changes made."
fi
