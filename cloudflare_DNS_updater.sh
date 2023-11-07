#!/bin/bash

# This script updates my DNS A and a specific TXT record on CloudFlare for my self hosted mail server since my ISP doesn't give static IP for free. 
# It is designed to first check if the external IP matches the current A record, and the proceeds the change if needed. 
# This is so that it only makes API calls as needed.  
# To find the records IDs, I had to use the API to query my DNS entries as it's not info that is not found on the CloudFlare dashboard.

# This bellow will cause the script to exit if any commands fail (non-zero exit status), if any variables are used before being set, 
# and if any part of a pipeline fails, not just the last command
set -euo pipefail

# Setting them fancy variables to make it easy to adjust/customise 

CLOUDFLARE_API_KEY="API KEY"
CLOUDFLARE_ZONE_ID="CloudFlare ZONE ID"
CLOUDFLARE_A_RECORD_ID="Specific A record ID"
CLOUDFLARE_TXT_RECORD_ID="Specific TXT record"
CLOUDFLARE_A_RECORD_WEBSITE="mail.example.com"
CLOUDFLARE_TXT_RECORD_NAME="example.com"
NEW_IP=$(curl -s -X GET https://checkip.amazonaws.com)

get_current_a_record_ip() {
    curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$CLOUDFLARE_A_RECORD_ID" \
    -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" | jq -r '.result.content'
}

CURRENT_A_RECORD_IP=$(get_current_a_record_ip)

# This is the cool part where the script will compare the current external IP with the A record you want updated. 

if [ "$NEW_IP" != "$CURRENT_A_RECORD_IP" ]; then
    # Update A record
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$CLOUDFLARE_A_RECORD_ID" \
    -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" \
    --data '{"type":"A","name":"'$CLOUDFLARE_A_RECORD_WEBSITE'","content":"'$NEW_IP'","ttl":1,"proxied":false}'

    # Check if the command was successful
    if [ $? -ne 0 ]; then
        echo "Failed to update A record"
        exit 1
    fi

    # Update TXT record
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLARE_ZONE_ID/dns_records/$CLOUDFLARE_TXT_RECORD_ID" \
    -H "Authorization: Bearer $CLOUDFLARE_API_KEY" \
    -H "Content-Type: application/json" \
    --data '{"type":"TXT","name":"'$CLOUDFLARE_TXT_RECORD_NAME'","content":"v=spf1 ip4:'$NEW_IP' -all","ttl":1}'

    # Check if the command was successful
    if [ $? -ne 0 ]; then
        echo "Failed to update TXT record"
        exit 1
    fi
else
    echo "IP is up-to-date"
fi
