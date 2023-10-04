//API_URL = "http://test-metadaten-nrw.hbz-nrw.de:1339/api/rpb-authorities";
API_URL = "http://localhost:1339/api/rpb-authorities";

// FLUX_DIR + "output/output-sw-strapi.ndjson"
FLUX_DIR + "output/test-output-sw.json"
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