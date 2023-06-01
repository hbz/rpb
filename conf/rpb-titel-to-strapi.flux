default outfile = "conf/output/output-strapi.ndjson";
FLUX_DIR + "RPB-Export_HBZ_Tit.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| encode-json(prettyPrinting="false")
| write(outfile)
;
