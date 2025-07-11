#!/bin/bash
set -e

# The data to be filtered
output="etl/maps/gndId-to-label.tsv"
tsv="${output}.all"

# The RPB and RPPD data files to search for GND IDs
data_files=(
  "etl/output/rppd-export.jsonl"
  "etl/output/output-strapi.ndjson"
  "etl/output/output-strapi-external.ndjson"
)

# See https://www.wikidata.org/wiki/Property:P227
# adapted to handle both `-` and `n` (used in RPB)
gnd_regex='1[0123]?[0-9]{7}[0-9X]|[47][0-9]{6}[n-][0-9]|[1-9][0-9]{0,7}[n-][0-9X]|3[0-9]{7}[0-9X]'

# Extract GND IDs used in current RPB and RPPD data
ids_file=$(mktemp)
for file in "${data_files[@]}"; do
  egrep -o "$gnd_regex" "$file"
done | sort -u > "$ids_file"

# Add IDs with '-' replaced by 'n'
awk '{print; gsub("-", "n"); print}' "$ids_file" | sort -u > "${ids_file}.all"

# Filter TSV: build `ids` set from IDs file, print TSV lines where $1 (GND ID) is in `ids`
awk -F'\t' 'NR==FNR{ids[$1]; next} ($1 in ids){print}' "${ids_file}.all" "$tsv" > "$output"

# Clean up IDs files
rm "$ids_file" "${ids_file}.all"
