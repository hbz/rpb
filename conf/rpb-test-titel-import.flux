API_URL = "http://test-metadaten-nrw.hbz-nrw.de:1339/api/" + PATH;
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
| open-http(url=API_URL, method="POST", contentType="application/json")
| as-lines
| print
;