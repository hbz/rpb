"http://lobid.org/gnd/search?q=type%3APlaceOrGeographicName+AND+NOT+type%3ABuildingOrMemorial+AND+NOT+type%3AWayBorderOrLine&format=jsonl"
| open-http
| as-lines
| decode-json
| fix("retain(id, preferredName)")
| encode-csv(includeheader="true", noquotes="true",separator="\t")
| write(FLUX_DIR + "maps/gndGeographicName.tsv")
;