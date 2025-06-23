#!/bin/bash
set -u
IFS=$'\n\t'

TIME=$(date "+%Y%m%d-%H%M")
INDEX="resources-rpb-$TIME"
ALIAS="resources-rpb-test"

RPB_INPUT="etl/output/output-strapi-external-rpb.ndjson"
RPB_URL="http://test.rpb.lobid.org/"

VINO_INPUT="etl/output/output-strapi-external-vino.ndjson"
VINO_URL="http://test.wein.lobid.org/"

RPB_SECRET=""

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/

# Transform the Strapi data

# Get rpb-authority data from Strapi export:
zgrep -a '"type":"api::rpb-authority.rpb-authority"' etl/strapi-export.tar.gz > etl/output/output-strapi-sw.ndjson
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rpb-sw.flux" # creates TSV lookup file for to-lobid transformation

# Strapi title data export is incomplete, see https://jira.hbz-nrw.de/browse/RPB-202, so we don't use the approach above (rpb-authority, same for RPPD / person):
## zgrep -a -E '"type":"api::article.article"|"type":"api::independent-work.independent-work"' etl/strapi-export.tar.gz > etl/output/output-strapi.ndjson
# Instead, we use the backup exports created in Strapi lifecycle afterCreate and afterUpdate hooks (copy from backup/ in Strapi instance):
cat etl/articles.ndjson | grep '"data"' | jq -c .data > etl/output/output-strapi.ndjson
cat etl/independent_works.ndjson | grep '"data"' | jq -c .data >> etl/output/output-strapi.ndjson
# External records:
cat etl/external_records.ndjson | grep '"data"' | jq -c .data > etl/output/output-strapi-external.ndjson
cat etl/output/output-strapi-external.ndjson | grep '"nur RPB"\|"RPB und BiblioVino"' > etl/output/output-strapi-external-rpb.ndjson
cat etl/output/output-strapi-external.ndjson | grep '"nur BiblioVino"\|"RPB und BiblioVino"' > etl/output/output-strapi-external-vino.ndjson
# Remove old index data:
rm etl/output/bulk/bulk-*.ndjson
# Transform:
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rpb-titel-to-lobid.flux index=$INDEX"

# Index to Elasticsearch:
unset http_proxy # for posting to weywot3
curl -XPUT -H "Content-Type: application/json" weywot3:9200/$INDEX?pretty -d @../lobid-resources-rpb/src/main/resources/alma/index-config.json
rm etl/output/es-curl-post.log
for filename in `ls -v etl/output/bulk/bulk-*.ndjson`
do
	echo "$filename"
	curl -XPOST --silent --show-error --fail --header 'Content-Type: application/x-ndjson' --data-binary @"$filename" 'weywot3:9200/_bulk' >> etl/output/es-curl-post.log
done

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
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rpb-titel-to-lobid-external.flux input=$RPB_INPUT url=$RPB_URL secret=$RPB_SECRET"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rpb-titel-to-lobid-external.flux input=$VINO_INPUT url=$VINO_URL secret=$RPB_SECRET"

# Delete in Elasticsearch:
cat etl/articles.ndjson | grep '"delete"' | jq --raw-output .delete.rpbId > etl/delete.ndjson
cat etl/independent_works.ndjson | grep '"delete"' | jq --raw-output .delete.rpbId >> etl/delete.ndjson
while read rpbId; do
   curl -X DELETE "weywot3:9200/$INDEX/resource/https%3A%2F%2Flobid.org%2Fresources%2F$rpbId"
done < etl/delete.ndjson
