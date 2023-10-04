//API_URL = "http://test-metadaten-nrw.hbz-nrw.de:1339/api/rppds";
API_URL = "http://localhost:1339/api/rppds";

// FLUX_DIR + "output/output-rppd-strapi.ndjson"
FLUX_DIR + "output/test-output-rppd.json"
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
