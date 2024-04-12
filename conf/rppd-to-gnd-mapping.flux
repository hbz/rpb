FLUX_DIR + "output/rppd-export.jsonl"
| open-file
| as-lines
| decode-json(recordPath="data")
| fix(FLUX_DIR + "rppd-to-gnd-map.fix")
| encode-csv(includeheader="true", noquotes="true",separator="\t")
| write(FLUX_DIR + "maps/gndId-to-rppdId.tsv")
;