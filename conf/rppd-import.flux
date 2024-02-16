default HOST = "localhost"; // pass e.g. HOST=test-metadaten-nrw.hbz-nrw.de
default IN_FILE = "test-output-rppd.json"; // pass e.g. IN_FILE=output-rppd-strapi.ndjson
API_URL = "http://" + HOST + ":1337/api/rppds";

FLUX_DIR + "output/" + IN_FILE
| open-file
| as-lines
| regex-decode("(?<data>.+)")
| stream-to-triples
| template("{\"${p}\":${o}}") // wrap into 'data' object for strapi
| log-object("Will POST: ")
| open-http(url=API_URL, method="POST", contentType="application/json")
| as-lines
| log-object("POST Response: ")
;
