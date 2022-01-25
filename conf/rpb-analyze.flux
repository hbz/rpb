"/home/acka47/Dokumente/hbz/rpb/testdaten/RPB-Export_HBZ_Titel.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix("retain('#98')")
| stream-to-triples
| count-triples(countBy="predicate")
| print
;