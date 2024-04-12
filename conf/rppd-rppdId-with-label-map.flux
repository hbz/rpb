FLUX_DIR + "output/rppd-export.jsonl"
| open-file
| as-lines
| decode-json(recordPath="data")
| fix(FLUX_DIR + "rppd-rppdId-with-label-map.fix")
| encode-csv(includeheader="true", noquotes="true",separator="\t")
| write(FLUX_DIR + "maps/rppdId-with-label.tsv")
;
