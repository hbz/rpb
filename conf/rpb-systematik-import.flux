API_URL = "http://test-metadaten-nrw.hbz-nrw.de:1339/api/" + PATH;

"https://raw.githubusercontent.com/acka47/scripts/master/skos2json/" + INPUT
| open-http
| as-lines
| regex-decode("(?<data>.+)")
| stream-to-triples
| template("{\"${p}\":${o}}") // wrap into 'data' object for strapi
| log-object("Will POST: ")
| open-http(url=API_URL, method="POST", contentType="application/json")
| as-lines
| log-object("POST Response: ")
;
