// Get test data for the specified type; for each record,
// fetch the entry from Strapi, convert that to lobid, write.

// sbt "runMain rpb.ETL etl/rppd-to-strapi.flux IN_FILE=RPB-Export_HBZ_Bio_Test.txt OUT_FILE=test-output-rppd.json"
// sbt -mem 2048 "runMain rpb.ETL etl/test-export-compare-rppd.flux"
default dynamicMapPath ="./maps/test/";

FLUX_DIR + "output/test-output-rppd.json"
| open-file
| as-lines
| decode-json
| fix("
prepend(rppdId, 'https://rpb-cms-test.lobid.org/api/persons?populate=*&filters[rppdId][$eq]=')
retain(rppdId)
")
| literal-to-object
| log-object("Strapi URL: ")
| open-http
| as-records
| decode-json(recordPath="data.[*].attributes")
| fix(FLUX_DIR + "rppd-to-lobid.fix",*)
| encode-json
| write(FLUX_DIR + "output/test-rppd-output-from-strapi.json")
;

// To compare, convert test data directly to lobid, write.
FLUX_DIR + "output/test-output-rppd.json"
| open-file
| as-lines
| decode-json
| fix(FLUX_DIR + "rppd-to-lobid.fix",*)
| encode-json
| write(FLUX_DIR + "output/test-rppd-output-from-file.json")
;
