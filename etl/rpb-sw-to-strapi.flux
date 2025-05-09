default OUT_FILE = "test-output-sw.json"; // pass e.g. OUT_FILE=output-sw-strapi.ndjson
default IN_FILE = "RPB-Export_HBZ_SW_Test.txt"; // pass e.g. IN_FILE=RPB-Export_HBZ_SW.txt
// (wget http://lobid.org/download/rpb-gesamtexport/2023-06-01/RPB-Export_HBZ_SW.txt)

FLUX_DIR + IN_FILE
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FLUX_DIR + "rpb-sw-to-strapi.fix")
| encode-json(prettyPrinting="false", booleanMarker="~")
| write(FLUX_DIR + "output/" + OUT_FILE)
;
