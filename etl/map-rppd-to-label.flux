FLUX_DIR + "output/rppd-export.jsonl"
| open-file
| as-lines
| decode-json(recordPath="data")
| fix(FLUX_DIR + "map-rppd-to-label.fix")
| encode-csv(includeheader="true", noquotes="true",separator="\t")
| write(FLUX_DIR + "maps/rppdId-to-label.tsv")
;
