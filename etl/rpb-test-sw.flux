FLUX_DIR + "RPB-Export_HBZ_SW_Test.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix("
paste('row', 'f00_', 'f3na', join_char : '\t')
retain(row)
")
| stream-to-triples
| template("${o}")
| write(FLUX_DIR + "output/sw-test-output.tsv")
;