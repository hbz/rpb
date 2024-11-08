#!/bin/bash
set -u
IFS=$'\n\t'

TIME=$(date "+%Y%m%d-%H%M")
INDEX="resources-rpb-$TIME"
ALIAS="resources-rpb-test"

# Here, we still import Allegro data:
# Get the daily Allegro dump:
cd conf
wget http://www.rpb-rlp.de/rpb/rpb04/intern/RPBEXP.zip
unzip -o RPBEXP.zip
mv RPBEXP.zip RPBEXP/RPBEXP-$TIME.zip
cd ..
sbt "runMain rpb.ETL conf/rpb-sw.flux"
sbt "runMain rpb.ETL conf/rpb-titel-to-strapi.flux"
# But now we also use the Strapi export and backup data:

# Transform the Strapi data:
# After switching rpb-authority cataloging from Allegro to Strapi:
## zgrep -a '"type":"api::rpb-authority.rpb-authority"' conf/strapi-export.tar.gz > conf/output/output-strapi-sw.ndjson
# Strapi title data export is incomplete, see https://jira.hbz-nrw.de/browse/RPB-202
## zgrep -a -E '"type":"api::article.article"|"type":"api::independent-work.independent-work"' conf/strapi-export.tar.gz > conf/output/output-strapi.ndjson
# Instead, we use the backup exports created in Strapi lifecycle afterCreate and afterUpdate hooks (copy from backup/ in Strapi instance):
cat conf/articles.ndjson | jq -c .data >> conf/output/output-strapi.ndjson
# After switching independent-works cataloging from Allegro to Strapi, use Strapi data only:
## cat conf/articles.ndjson | jq -c .data > conf/output/output-strapi.ndjson
## cat conf/independent_works.ndjson | jq -c .data >> conf/output/output-strapi.ndjson
# Remove old index data:
rm conf/output/bulk/bulk-*.ndjson
## sbt "runMain rpb.ETL conf/rpb-sw.flux" # creates TSV lookup file for to-lobid transformation
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
curl -X POST "weywot3:9200/_aliases?pretty" -H 'Content-Type: application/json' -d'
{
	"actions" : [
		{ "remove" : { "index" : "*", "alias" : "'"$ALIAS"'" } },
		{ "add" : { "index" : "'"$INDEX"'", "alias" : "'"$ALIAS"'" } }
	]
}
'
