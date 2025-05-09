// Defaults, use Allegro test data:
// sbt "runMain rpb.ETL conf/rppd-to-strapi.flux IN_FILE=RPB-Export_HBZ_Bio_Test.txt OUT_FILE=test-output-rppd.json"
// sbt "runMain rpb.ETL conf/rppd-test-to-lobid.flux"

// To use Strapi export test data:
// zgrep -a '"type":"api::person.person"' conf/strapi-export-test.tar.gz > conf/output/test-rppd-export.json
// sbt "runMain rpb.ETL conf/rppd-test-to-lobid.flux IN_FILE=test-rppd-export.json RECORD_PATH=data"

default IN_FILE = "test-output-rppd.json"; // pass e.g. IN_FILE=test-rppd-export.json
default RECORD_PATH = ""; // pass e.g. RECORD_PATH=data

FLUX_DIR + "output/" + IN_FILE
| open-file
| as-lines
| decode-json(recordPath=RECORD_PATH)
| fix(FLUX_DIR + "rppd-to-lobid.fix")
| batch-reset(batchsize="1")
| encode-json(prettyPrinting="true")
| write(FLUX_DIR + "output/test-output-rppd-lobid-${i}.json")
;