FLUX_DIR + "output/rppd-export.jsonl"
| open-file
| as-lines
| decode-json(recordPath="data")
| fix(FLUX_DIR + "map-gnd-person-to-label.fix")
| encode-csv(includeheader="true", noquotes="true",separator="\t")
| write(FLUX_DIR + "maps/gndId-to-label.tsv")
;