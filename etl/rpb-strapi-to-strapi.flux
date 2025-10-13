// Create a shell script to update a specific field in Strapi
// (spatial for RPB-179; subject and spatial for RPB-301),
// using curl and the Strapi update API (can't send from here, need ID in path):
// https://docs-v4.strapi.io/dev-docs/api/rest#update-an-entry

// Pass the Fix file, the specific Strapi data type, host, and API token to be used:
// (expects REVERSED files articles.ndjson, independent-works.ndjson, external-records.ndjson;
// reverse files with e.g. `tac articles-from-strapi-server.ndjson > articles.ndjson`)
// sbt "runMain rpb.ETL etl/rpb-strapi-to-strapi.flux FIX_FILE=rpb-strapi-to-strapi-rpb-179.fix TYPE=articles HOST=test-metadaten-nrw:1339 API_TOKEN=bb0..."
// bash -x etl/output/rpb-strapi-update.sh

default TYPE = "articles"; // pass TYPE=articles, TYPE=independent-works, TYPE=external-records
default HOST = "localhost:1337"; // pass e.g. HOST=test-metadaten-nrw:1339

FLUX_DIR + TYPE + ".ndjson"
| open-file
| as-lines
| rpb.FirstRecordOnly
| decode-json
| fix(FLUX_DIR + FIX_FILE)
| encode-json(prettyPrinting="false")
| match(pattern=".+?data..(.+)..id...(.+)..+", replacement="curl --no-progress-meter -X PUT -H 'Content-Type: application/json' -d '{\"data\":$1}' -H 'Authorization: Bearer " + API_TOKEN + "' -w '\\\\n' http://" + HOST + "/api/" + TYPE + "/$2")
| write(FLUX_DIR + "output/rpb-strapi-update.sh", appendIfFileExists="true")
;
