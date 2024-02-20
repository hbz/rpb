FLUX_DIR + "output/output-rppd-strapi.ndjson"
| open-file
| as-lines
| decode-json
| fix(FLUX_DIR + "rppd-to-gnd-map.fix")
| encode-csv(includeheader="true", noquotes="true",separator="\t")
| write(FLUX_DIR + "maps/gndId-to-rppdId.tsv")
;