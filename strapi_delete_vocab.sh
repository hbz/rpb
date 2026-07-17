#!/usr/bin/env bash

# This script deletes all entries for given CONTENT_TYPE aka PATH, e.g. rpb-notations
# see https://docs-v4.strapi.io/dev-docs/api/rest

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <content-type>"
    exit 1
fi

source .env

: "${HOST:?Set HOST via environment variable}"
: "${API_TOKEN:?Set API_TOKEN via environment variable}"

STRAPI_URL="http://"$HOST":1339"

echo "STRAPI_URL: $STRAPI_URL"

CONTENT_TYPE="$1"

PAGE_SIZE=100 # 100 is max number of entries strapi delivers

echo "Get number of entries..."

COUNT=$(curl -s \
    "${STRAPI_URL}/api/${CONTENT_TYPE}?pagination\[page\]=1&pagination\[pageSize\]=1" \
    | jq '.meta.pagination.total')

if [[ "$COUNT" -eq 0 ]]; then
    echo "No entries found."
    exit 0
fi

echo
echo "$COUNT entries of type '${CONTENT_TYPE}' will be deleted."
echo

DELETED=0

while true; do

    # get first page, up to 100 IDs
    RESPONSE=$(curl -s \
        "${STRAPI_URL}/api/${CONTENT_TYPE}?fields\[0\]=id&pagination\[page\]=1&pagination\[pageSize\]=${PAGE_SIZE}")

    IDS=$(echo "$RESPONSE" | jq -r '.data[].id')

    # if no more IDs found
    if [[ -z "$IDS" ]]; then
	echo "No other IDs found. Finished."
	break
    fi

    # delete IDs
    while read -r ID; do

        printf "Delete %s/%s ... " "$CONTENT_TYPE" "$ID"

        HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
            -X DELETE \
	    -H "Authorization: Bearer ${API_TOKEN}" \
            "${STRAPI_URL}/api/${CONTENT_TYPE}/${ID}")

        if [[ "$HTTP_CODE" == "200" ]]; then
            echo "OK"
            DELETED=$((DELETED + 1))
        else
            echo "ERROR (HTTP $HTTP_CODE)"
        fi
    done <<< "$IDS"
done

echo
echo "$DELETED entries deleted."
