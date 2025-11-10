"https://lobid.org/gnd/search?format=jsonl"
| open-http(acceptEncoding="gzip")
| as-lines
| decode-json
| fix("
    join_field('variantName[]', '; ')
    move_field('variantName[]', variantName)
    retain(gndIdentifier, preferredName, variantName)
")
| encode-csv(includeHeader="true", noQuotes="true", separator="\t")
| write(FLUX_DIR + "maps/gndId-to-label.tsv.all")
;
