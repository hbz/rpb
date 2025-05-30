"/home/acka47/Documents/hbz/rpb/testdaten/2022-03-11/RPB-Export_HBZ_Tit.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FLUX_DIR + "stats.fix")
| stream-to-triples
| count-triples(countBy = "object")
| template("${o} | ${s}")
| print
;