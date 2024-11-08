//After switching rpb-authority cataloging from Allegro to Strapi:
//FLUX_DIR + "output/output-strapi-sw.ndjson"
//| open-file
FLUX_DIR + "RPB-Export_HBZ_SW.txt"
| open-file(encoding="IBM437")
| as-lines
//After switching rpb-authority cataloging from Allegro to Strapi:
//| decode-json
| rpb.Decode
| fix("
#After switching rpb-authority cataloging from Allegro to Strapi:
#paste('row', 'data.rpbId', 'data.preferredName', join_char : '\t')
paste('row', 'f00_', 'f3na', join_char : '\t')
retain(row)
")
| stream-to-triples
| template("${o}")
| write(FLUX_DIR + "RPB-Export_HBZ_SW.tsv")
;