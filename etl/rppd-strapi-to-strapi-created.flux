// Create a shell script to update a specific field in Strapi (created),
// using curl and the Strapi update API (can't send from here, need ID in path):
// https://docs.strapi.io/dev-docs/api/rest#update-an-entry

// Use export data from Allegro (for `f95_` values) and Strapi (for record `id`), merged via `rppdId`:
// sbt "runMain rpb.ETL etl/rppd-to-strapi.flux IN_FILE=RPB-Export_HBZ_Bio.txt OUT_FILE=output-rppd-strapi.ndjson"
// zgrep -a '"type":"api::person.person"' etl/strapi-export.tar.gz > etl/output/rppd-export.jsonl
// sbt "runMain rpb.ETL etl/rppd-strapi-to-strapi-created.flux HOST=test-metadaten-nrw:1339 API_TOKEN=bb0..."
// bash etl/output/rppd-strapi-update.sh

default HOST = "localhost:1337"; // pass e.g. HOST=test-metadaten-nrw:1339
default API_TOKEN = ""; // pass e.g. API_TOKEN=bb0...

"etl/output/rppd-export.jsonl"
| open-file
| as-lines
| decode-json
| fix("
unless all_match('data.rppdId', 'p.+')
  reject()
end
move_field('data.rppdId', '_id')
retain('id', '_id')
")
| stream-to-triples(redirect="true")
| @X;

"etl/output/output-rppd-strapi.ndjson"
| open-file
| as-lines
| decode-json
| fix("
move_field('rppdId', '_id')
move_field('f95_', 'data.created')
retain('data.created', '_id')
")
| stream-to-triples(redirect="true")
| @X;

@X
| wait-for-inputs("2")
| sort-triples(by="subject")
| collect-triples
| encode-json(prettyPrinting="false")
| match(pattern=".+?id...(.+)...data..(.+).+", replacement="curl -X PUT -H 'Content-Type: application/json' -d '{\"data\":$2}' -H 'Authorization: Bearer " + API_TOKEN + "' -w '\\\\n' http://" + HOST + "/api/persons/$1")
| write(FLUX_DIR + "output/rppd-strapi-update.sh")
;
