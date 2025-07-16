"https://lobid.org/gnd/search?format=jsonl"
| open-http(acceptEncoding="gzip")
| as-lines
| decode-json
| fix("retain(gndIdentifier, preferredName)")
| encode-csv(includeHeader="true", noQuotes="true", separator="\t")
| write(FLUX_DIR + "maps/gndId-to-label.tsv.all")
;
