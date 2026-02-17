FLUX_DIR + "output/output-strapi-sw.ndjson"
| open-file
| as-lines
| decode-json
| fix("
set_array('variantNames')
copy_field('data.variantName[].*.value', 'variantNames.$append')
join_field('variantNames', '; ')
paste('row', 'data.rpbId', 'data.preferredName', 'variantNames', join_char : '\t')
retain(row)
")
| stream-to-triples
| template("${o}")
| match(pattern="\n", replacement=";")
| write(FLUX_DIR + "RPB-Export_HBZ_SW.tsv")
;