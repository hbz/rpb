#!/bin/bash
set -euxo pipefail

# Delete matching non-aliased indices, but keep the newest

HOST="localhost"
INDICES=("gnd-rppd-*" "resources-rpb-*")

for INDEX in "${INDICES[@]}"
do
    curl -s -S -X GET "$HOST:9200/_cluster/state?filter_path=metadata.indices.$INDEX.aliases&pretty" |
    jq -r '.metadata.indices | to_entries[] | select(.value.aliases | length == 0) | .key' | # no alias
    sort | head -n -1 | # don't include the newest index
    awk -v HOST="$HOST" '{print HOST":9200/"$1"?pretty"}' |
    xargs -L 1 curl -s -S -v -X DELETE
done
