// Import / restore from Strapi export data:
// zgrep -a '"type":"api::person.person"' conf/strapi-export.tar.gz > conf/output/rppd-export-restore.jsonl
// sbt "runMain rpb.ETL conf/rppd-import-from-strapi.flux IN_FILE=rppd-export-restore.jsonl HOST=$HOST API_TOKEN=$API_TOKEN"

default HOST = "localhost"; // pass e.g. HOST=test-metadaten-nrw.hbz-nrw.de
default IN_FILE = "rppd-export.jsonl"; // pass e.g. IN_FILE=rppd-export-restore.jsonl
default API_TOKEN = ""; // pass e.g. API_TOKEN=e8d...
API_URL = "http://" + HOST + ":1337/api/persons";

FLUX_DIR + "output/" + IN_FILE
| open-file
| as-lines
| log-object("Will POST: ")
| open-http(url=API_URL, method="POST", contentType="application/json", header="Authorization: Bearer " + API_TOKEN)
| as-lines
| log-object("POST Response: ")
;
