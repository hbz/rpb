#!/bin/bash
set -u
IFS=$'\n\t'

TIME=$(date "+%Y%m%d-%H%M")
INDEX="resources-rpb-$TIME"
ALIAS="resources-rpb-test"

# Transform the Strapi data

# Get rpb-authority data from Strapi export:
zgrep -a '"type":"api::rpb-authority.rpb-authority"' conf/strapi-export.tar.gz > conf/output/output-strapi-sw.ndjson
sbt "runMain rpb.ETL conf/rpb-sw.flux" # creates TSV lookup file for to-lobid transformation

# Strapi title data export is incomplete, see https://jira.hbz-nrw.de/browse/RPB-202, so we don't use the approach above (rpb-authority, same for RPPD / person):
## zgrep -a -E '"type":"api::article.article"|"type":"api::independent-work.independent-work"' conf/strapi-export.tar.gz > conf/output/output-strapi.ndjson
# Instead, we use the backup exports created in Strapi lifecycle afterCreate and afterUpdate hooks (copy from backup/ in Strapi instance):
cat conf/articles.ndjson | grep '"data"' | jq -c .data > conf/output/output-strapi.ndjson
cat conf/independent_works.ndjson | grep '"data"' | jq -c .data >> conf/output/output-strapi.ndjson
# Remove old index data:
rm conf/output/bulk/bulk-*.ndjson
sbt "runMain rpb.ETL conf/rpb-titel-to-lobid.flux index=$INDEX"

# Index to Elasticsearch:
unset http_proxy # for posting to weywot3
curl -XPUT -H "Content-Type: application/json" weywot3:9200/$INDEX?pretty -d @../lobid-resources-rpb/src/main/resources/alma/index-config.json
rm conf/output/es-curl-post.log
for filename in conf/output/bulk/bulk-*.ndjson
do
	echo "$filename"
	curl -XPOST --silent --show-error --fail --header 'Content-Type: application/x-ndjson' --data-binary @"$filename" 'weywot3:9200/_bulk' >> conf/output/es-curl-post.log
done

# Delete in Elasticsearch:
cat conf/articles.ndjson | grep '"delete"' | jq --raw-output .delete.rpbId > conf/delete.ndjson
cat conf/independent_works.ndjson | grep '"delete"' | jq --raw-output .delete.rpbId >> conf/delete.ndjson
while read rpbId; do
   curl -X DELETE "weywot3:9200/$INDEX/resource/https%3A%2F%2Flobid.org%2Fresources%2F$rpbId"
done < conf/delete.ndjson

# Move alias to new index:
curl -X POST "weywot3:9200/_aliases?pretty" -H 'Content-Type: application/json' -d'
{
	"actions" : [
		{ "remove" : { "index" : "*", "alias" : "'"$ALIAS"'" } },
		{ "add" : { "index" : "'"$INDEX"'", "alias" : "'"$ALIAS"'" } }
	]
}
'
