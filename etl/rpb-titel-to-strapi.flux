default outfile = "etl/output/output-strapi.ndjson";
FLUX_DIR + "RPB-Export_HBZ_Tit.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FLUX_DIR + "rpb-titel-to-strapi.fix")
| encode-json(prettyPrinting="false", booleanMarker="~")
| write(outfile)
;
