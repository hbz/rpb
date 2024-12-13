FLUX_DIR + "output/output-strapi-sw.ndjson"
| open-file
| as-lines
| decode-json
| fix("
paste('row', 'data.rpbId', 'data.preferredName', join_char : '\t')
retain(row)
")
| stream-to-triples
| template("${o}")
| write(FLUX_DIR + "RPB-Export_HBZ_SW.tsv")
;