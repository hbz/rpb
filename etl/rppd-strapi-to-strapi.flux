// Create a shell script to update a specific field in Strapi (relatedPerson),
// using curl and the Strapi update API (can't send from here, need ID in path):
// https://docs.strapi.io/dev-docs/api/rest#update-an-entry

// Use Strapi export data, then run with host and API token to be used:
// zgrep -a '"type":"api::person.person"' etl/strapi-export.tar.gz > etl/output/rppd-export.jsonl
// sbt "runMain rpb.ETL etl/rppd-strapi-to-strapi.flux HOST=test-metadaten-nrw:1339 API_TOKEN=bb0..."
// bash etl/output/rppd-strapi-update.sh

default HOST = "localhost:1337"; // pass e.g. HOST=test-metadaten-nrw:1339
default API_TOKEN = ""; // pass e.g. API_TOKEN=bb0...

"etl/output/rppd-export.jsonl"
| open-file
| as-lines
| decode-json
| fix("
if is_empty('data.relatedPerson[]')
    reject()
end
do once('map')
  put_filemap('etl/maps/gndId-to-label.tsv', 'label_to_gnd', key_column:'1', value_column:'0', sep_char: '\t', expected_columns:'-1')
end
do list_as(person: 'data.relatedPerson[].*')
    copy_field('person.value', _temp)
    lookup(_temp, 'label_to_gnd', delete: 'true')
    if exists(_temp)
        prepend(_temp, 'http://rppd.lobid.org/')
        move_field(_temp, 'person.value')
    end
    remove_field('person.id')
end
retain('id', 'data.relatedPerson[]')
")
| encode-json(prettyPrinting="false")
| match(pattern=".+?id...(.+)...data..(.+).+", replacement="curl -X PUT -H 'Content-Type: application/json' -d '{\"data\":$2}' -H 'Authorization: Bearer " + API_TOKEN + "' -w '\\\\n' http://" + HOST + "/api/persons/$1")
| write(FLUX_DIR + "output/rppd-strapi-update.sh")
;
