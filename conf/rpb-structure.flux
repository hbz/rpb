FLUX_DIR + "RPB-Export_HBZ_Titel_Test.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix("vacuum()")
| flatten
| stream-to-triples
| count-triples(countBy="PREDICATE")
| sort-triples(By="SUBJECT")
| template("${o}\t${s}")
| write(FLUX_DIR + "structure.txt")
;