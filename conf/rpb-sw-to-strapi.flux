// default outfile = "conf/output/output-sw-strapi.ndjson";
default outfile = "conf/output/test-output-sw.json";

// wget http://lobid.org/download/rpb-gesamtexport/2023-06-01/RPB-Export_HBZ_SW.txt
// FLUX_DIR + "RPB-Export_HBZ_SW.txt"
FLUX_DIR + "RPB-Export_HBZ_SW_Test.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FLUX_DIR + "rpb-sw-to-strapi.fix")
| encode-json(prettyPrinting="false", booleanMarker="~")
| write(outfile)
;
