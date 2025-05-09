default OUT_FILE = "test-output-rppd.json"; // pass e.g. OUT_FILE=output-rppd-strapi.ndjson
default IN_FILE = "RPB-Export_HBZ_Bio_Test.txt"; // pass e.g. IN_FILE=RPB-Export_HBZ_Bio.txt
// (wget http://lobid.org/download/rpb-gesamtexport/2023-06-01/RPB-Export_HBZ_Bio.txt)

FLUX_DIR + IN_FILE
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FLUX_DIR + "rppd-to-strapi.fix")
| encode-json(prettyPrinting="false", booleanMarker="~")
| write(FLUX_DIR + "output/" + OUT_FILE)
;
