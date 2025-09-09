// Create a shell script to update a specific field in Strapi (spatial, for RPB-179),
// using curl and the Strapi update API (can't send from here, need ID in path):
// https://docs-v4.strapi.io/dev-docs/api/rest#update-an-entry

// Pass the specific Strapi data type, host, and API token to be used:
// (expects files articles.ndjson, independent-works.ndjson, external-records.ndjson)
// sbt "runMain rpb.ETL etl/rpb-strapi-to-strapi.flux TYPE=articles HOST=test-metadaten-nrw:1339 API_TOKEN=bb0..."
// bash etl/output/rpb-strapi-update.sh

default TYPE = "articles"; // pass TYPE=articles, TYPE=independent-works, TYPE=external-records
default HOST = "localhost:1337"; // pass e.g. HOST=test-metadaten-nrw:1339
default API_TOKEN = ""; // pass e.g. API_TOKEN=bb0...

"etl/" + TYPE + ".ndjson"
| open-file
| as-lines
| decode-json
| fix("
do once('map')
    put_rdfmap('etl/maps/rpb-spatial.ttl', 'spatial_map', target:'skos:prefLabel', select_language:'de')
end
do list_as(spatial: 'data.spatial[].*')
    if all_match('spatial.value', '^_.+?_ _.+_$')
        # Case 1: '_r19_ _00Sn02m0557a_' -> 'https://rpb.lobid.org/spatial#n00Sn02m0557a'
        replace_all('spatial.value', '_.+?_ _(.+)_$', 'https://rpb.lobid.org/spatial#n$1')
        set_field(_changed, 'true')
    elsif all_match('spatial.value', '^https://d-nb.info/gnd/.+')
        # Case 2: 'https://d-nb.info/gnd/4076027-3' -> 'https://rpb.lobid.org/spatial#n4076027n3'
        replace_all('spatial.value', 'https://d-nb.info/gnd/([0-9]+)-([0-9]+|X)', 'https://rpb.lobid.org/spatial#n$1n$2')
        copy_field('spatial.value', _label)
        lookup(_label, 'spatial_map', delete: 'true')
        if exists(_label)
            set_field(_changed, 'true')
        end
    end
    # ID and label are managed by Strapi, we only update 'spatial.value':
    remove_field('spatial.id')
    remove_field('spatial.label')
end
unless exists(_changed)
    reject()
end
uniq('data.spatial[]')
copy_field('data.id', 'id')
retain('data.spatial[]', 'id')
")
| encode-json(prettyPrinting="false")
| match(pattern=".+?data..(.+)..id...(.+)..+", replacement="curl -X PUT -H 'Content-Type: application/json' -d '{\"data\":$1}' -H 'Authorization: Bearer " + API_TOKEN + "' -w '\\\\n' http://" + HOST + "/api/" + TYPE + "/$2")
| write(FLUX_DIR + "output/rpb-strapi-update.sh")
;
