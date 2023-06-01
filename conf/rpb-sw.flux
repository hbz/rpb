FLUX_DIR + "RPB-Export_HBZ_SW.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix("
paste('row', '#00 ', '#3na', join_char : '\t')
retain(row)
")
| stream-to-triples
| template("${o}")
| write(FLUX_DIR + "RPB-Export_HBZ_SW.tsv")
;