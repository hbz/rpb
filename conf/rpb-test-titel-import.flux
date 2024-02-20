default HOST = "localhost"; // pass e.g. test-metadaten-nrw.hbz-nrw.de
default API_TOKEN = ""; // pass e.g. API_TOKEN=e8d...
API_URL = "http://" + HOST + ":1337/api/" + PATH;

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
| open-http(url=API_URL, method="POST", contentType="application/json", header="Authorization: Bearer " + API_TOKEN)
| as-lines
| log-object("POST Response: ")
;
