#!/bin/bash
set -u
IFS=$'\n\t'

TIME=$(date "+%Y%m%d-%H%M")
INDEX="resources-rpb-$TIME"
ALIAS="resources-rpb-test"

RPB_INPUT="conf/output/output-strapi-external-rpb.ndjson"
RPB_URL="http://test.rpb.lobid.org/"

VINO_INPUT="conf/output/output-strapi-external-vino.ndjson"
VINO_URL="http://test.wein.lobid.org/"

RPB_SECRET=""

# Transform the Strapi data

# Get rpb-authority data from Strapi export:
zgrep -a '"type":"api::rpb-authority.rpb-authority"' conf/strapi-export.tar.gz > conf/output/output-strapi-sw.ndjson
sbt "runMain rpb.ETL conf/rpb-sw.flux" # creates TSV lookup file for to-lobid transformation

# Strapi title data export is incomplete, see https://jira.hbz-nrw.de/browse/RPB-202, so we don't use the approach above (rpb-authority, same for RPPD / person):
## zgrep -a -E '"type":"api::article.article"|"type":"api::independent-work.independent-work"' conf/strapi-export.tar.gz > conf/output/output-strapi.ndjson
# Instead, we use the backup exports created in Strapi lifecycle afterCreate and afterUpdate hooks (copy from backup/ in Strapi instance):
cat conf/articles.ndjson | grep '"data"' | jq -c .data > conf/output/output-strapi.ndjson
cat conf/independent_works.ndjson | grep '"data"' | jq -c .data >> conf/output/output-strapi.ndjson
# External records:
cat conf/external_records.ndjson | grep '"data"' | jq -c .data > conf/output/output-strapi-external.ndjson
cat conf/output/output-strapi-external.ndjson | grep '"nur RPB"\|"RPB und BiblioVino"' > conf/output/output-strapi-external-rpb.ndjson
cat conf/output/output-strapi-external.ndjson | grep '"nur BiblioVino"\|"RPB und BiblioVino"' > conf/output/output-strapi-external-vino.ndjson
# Remove old index data:
rm conf/output/bulk/bulk-*.ndjson
# Transform:
sbt "runMain rpb.ETL conf/rpb-titel-to-lobid.flux index=$INDEX"

# Index to Elasticsearch:
unset http_proxy # for posting to weywot3
curl -XPUT -H "Content-Type: application/json" weywot3:9200/$INDEX?pretty -d @../lobid-resources-rpb/src/main/resources/alma/index-config.json
rm conf/output/es-curl-post.log
for filename in `ls -v conf/output/bulk/bulk-*.ndjson`
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

# Transform and index external records (after index switch, they use the RPB and BiblioVino instances):
sbt "runMain rpb.ETL conf/rpb-titel-to-lobid-external.flux input=$RPB_INPUT url=$RPB_URL secret=$RPB_SECRET"
sbt "runMain rpb.ETL conf/rpb-titel-to-lobid-external.flux input=$VINO_INPUT url=$VINO_URL secret=$RPB_SECRET"
