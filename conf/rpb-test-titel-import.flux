API_URL = "http://localhost:1339/api/" + PATH;
// API_URL = "http://test-metadaten-nrw.hbz-nrw.de:1339/api/" + PATH;
FIX = "
unless " + PICK + "
  reject()
end
";

FLUX_DIR + "output/test-output-strapi.json"
| open-file
| as-lines
| decode-json
| fix(FIX)
| encode-json
| regex-decode("(?<data>.+)")
| stream-to-triples
| template("{\"${p}\":${o}}") // wrap into 'data' object for strapi
| log-object("Will POST: ")
| open-http(url=API_URL, method="POST", contentType="application/json")
| as-lines
| log-object("POST Response: ")
;
