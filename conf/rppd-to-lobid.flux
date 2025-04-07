// Defaults, use Allegro data:
// sbt "runMain rpb.ETL conf/rppd-to-strapi.flux IN_FILE=RPB-Export_HBZ_Bio.txt OUT_FILE=output-rppd-strapi.ndjson"
// sbt "runMain rpb.ETL conf/rppd-to-lobid.flux"

// To use Strapi export data:
// zgrep -a '"type":"api::person.person"' conf/strapi-export.tar.gz > conf/output/rppd-export.json
// sbt "runMain rpb.ETL conf/rppd-to-lobid.flux IN_FILE=rppd-export.json RECORD_PATH=data"

default IN_FILE = "output-rppd-strapi.ndjson"; // pass e.g. OUT_FILE=output-rppd-export.ndjson
default RECORD_PATH = ""; // pass e.g. RECORD_PATH=data
default OUT_FILE = "conf/output/bulk/rppd/bulk-rppd-${i}.jsonl"; // lobid-gnd expects *.jsonl suffix
"conf/output/" + IN_FILE
| open-file
| as-lines
| decode-json(recordPath=RECORD_PATH)
| fix(FLUX_DIR + "rppd-to-lobid.fix")
| batch-reset(batchsize="1000")
| encode-json(prettyPrinting="false")
| json-to-elasticsearch-bulk(idkey="id", type="authority", index="gnd-rppd-test")
| write(OUT_FILE)
;
