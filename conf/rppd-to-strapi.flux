// default outfile = "conf/output/output-rppd-strapi.ndjson";
default outfile = "conf/output/test-output-rppd.json";

// wget http://lobid.org/download/rpb-gesamtexport/2023-06-01/RPB-Export_HBZ_Bio.txt
// FLUX_DIR + "RPB-Export_HBZ_Bio.txt"
FLUX_DIR + "RPB-Export_HBZ_Bio_Test.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FLUX_DIR + "rppd-to-strapi.fix")
| encode-json(prettyPrinting="false", booleanMarker="~")
| write(outfile)
;
