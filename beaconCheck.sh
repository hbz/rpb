#!/bin/bash
set -eu

# Default beacon URL if none provided
BEACON_URL=${1:-"https://rppd.lobid.org/beacon.txt"}
OUTPUT_FILE="beaconMissing.txt"
REQUESTS_PER_MINUTE=6000
SLEEP_TIME=$(bc <<< "60 / $REQUESTS_PER_MINUTE")

# Clear output file if it exists
> "$OUTPUT_FILE"

# Function to extract target pattern from beacon file
get_target_pattern() {
    grep "^#TARGET:" "$1" | sed 's/#TARGET: //'
}

# Download beacon file
wget -q "$BEACON_URL" -O beacon_temp.txt

if [ ! -f beacon_temp.txt ]; then
    echo "Failed to download beacon file from $BEACON_URL"
    exit 1
fi

TARGET_PATTERN=$(get_target_pattern beacon_temp.txt)

if [ -z "$TARGET_PATTERN" ]; then
    echo "No TARGET pattern found in beacon file"
    rm beacon_temp.txt
    exit 1
fi

# Process each ID in the beacon file
grep -v "^#" beacon_temp.txt | while read -r line; do
    if [ -n "$line" ]; then
        # Replace ID pattern in target URL
        URL="${TARGET_PATTERN//\{ID\}/$line}"
        
        # Make HTTP request with custom user agent and check response, following redirects
        response=$(curl -L -s -o /dev/null -w "%{http_code}" -A "RPPD beacon check; lobid-admin@hbz-nrw.de" "$URL")
        
        if [ "$response" != "200" ]; then
            echo "$URL" >> "$OUTPUT_FILE"
        fi
        
        # Sleep to respect rate limit
        sleep $SLEEP_TIME
    fi
done

# Clean up
rm beacon_temp.txt

echo "Check complete. Missing URLs have been written to $OUTPUT_FILE"
