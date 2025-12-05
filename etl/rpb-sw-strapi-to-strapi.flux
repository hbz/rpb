// Create a shell script to update a specific field in Strapi (variantName),
// using curl and the Strapi update API (can't send from here, need ID in path):
// https://docs-v4.strapi.io/dev-docs/api/rest#update-an-entry

// Use Strapi export data, then run with host and API token to be used:
// zgrep -a '"type":"api::rpb-authority.rpb-authority"' etl/strapi-export.tar.gz > etl/output/rpb-sw-export.jsonl
// sbt "runMain rpb.ETL etl/rpb-sw-strapi-to-strapi.flux HOST=test-metadaten-nrw:1339 API_TOKEN=bb0..."
// bash etl/output/rpb-sw-strapi-update.sh

default HOST = "localhost:1337"; // pass e.g. HOST=test-metadaten-nrw:1339

"etl/output/rpb-sw-export.jsonl"
| open-file
| as-lines
| decode-json
| fix("
copy_field('data.preferredName', '_temp')
rpb.StripDiacritics('_temp')
if in('data.preferredName', '_temp')
    reject()
end
unless exists('data.variantName[]')
    set_array('data.variantName[]')
end
do list_as('variantName': 'data.variantName[]')
  remove_field('variantName.id')
end
move_field('_temp', 'data.variantName[].$append.value')
retain('id', 'data.variantName[]')
")
| encode-json(prettyPrinting="false")
| match(pattern=".+?id...(.+)...data..(.+).+", replacement="curl -X PUT -H 'Content-Type: application/json' -d '{\"data\":$2}' -H 'Authorization: Bearer " + API_TOKEN + "' -w '\\\\n' http://" + HOST + "/api/rpb-authorities/$1")
| write(FLUX_DIR + "output/rpb-sw-strapi-update.sh")
;
