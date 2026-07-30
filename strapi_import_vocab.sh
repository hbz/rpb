#!/usr/bin/env bash

set -euo pipefail

source .env

: "${HOST:?Set HOST environment variable}"
: "${API_TOKEN:?Set API_TOKEN environment variable}"

RPB_REPO=/home/sol/git/rpb-test
VOCABS_REPO=/home/sol/git/lbz-vocabs

#
# Check if ndjson files have changed
#

cd "$VOCABS_REPO"

git switch main

# get changes from remote
git fetch origin

changed_files=$(git diff --name-only origin/main...HEAD -- '*.ndjson')

if [ -z "$changed_files" ]; then
    echo "No ndjson files changed."
    exit 0
fi

echo "Changed files:"
echo "$changed_files"

#
# Change to rpb repo
#

cd "$RPB_REPO"

import_vocab() {
    local input_file="$1"
    local import_path="$2"

    echo "Deleting ${import_path} in Strapi"
    if ! ./strapi_delete_vocab.sh "$import_path"; then
        echo "ERROR: strapi_delete_vocab.sh failed for '${import_path}'" >&2
        exit 1
    fi

    echo "Importing ${import_path} into Strapi"
    if ! sbt "runMain rpb.ETL etl/rpb-systematik-import.flux INPUT=${input_file} PATH=${import_path} HOST=$HOST API_TOKEN=$API_TOKEN"; then
        echo "ERROR: sbt import failed for '${input_file}' with PATH='${import_path}'" >&2
        exit 1
    fi
}

#
# First delete then import
#

while IFS= read -r file; do
    case "$file" in
        output/rpb.ndjson)
            import_vocab "rpb.ndjson" "rpb-notations"
            ;;
        output/rpb-spatial.ndjson)
            import_vocab "rpb-spatial.ndjson" "rpb-spatials"
            ;;
        output/rpb-fachgebiete.ndjson)
            import_vocab "rpb-fachgebiete.ndjson" "fachgebiets"
            ;;
        *)
            echo "No processing defined for $file"
            ;;
    esac

done <<< "$changed_files"

#
# Change back to lbz-vocabs repo and
# set/update local main branch from remote
#

cd "$VOCABS_REPO" && git reset --hard origin/main

