#!/bin/bash
set -eu
IFS=$'\n\t'

TIME=$(date "+%Y%m%d-%H%M")
INDEX="resources-rpb-$TIME"
ALIAS="resources-rpb-test"

# Get the daily Allegro dump:
cd conf
wget http://www.rpb-rlp.de/rpb/rpb04/intern/RPBEXP.zip
unzip -o RPBEXP.zip
mv RPBEXP.zip RPBEXP/RPBEXP-$TIME.zip
cd ..

# Transform the data:
sbt "runMain rpb.ETL conf/rpb-sw.flux"
sbt "runMain rpb.ETL conf/rpb-titel-to-strapi.flux"
sbt "runMain rpb.ETL conf/rpb-titel-to-lobid.flux index=$INDEX"

# Index to Elasticsearch:
unset http_proxy # for posting to weywot3
curl -XPUT -H "Content-Type: application/json" weywot3:9200/$INDEX?pretty -d @../lobid-resources-rpb/src/main/resources/alma/index-config.json
for filename in conf/output/bulk/bulk-*.ndjson
do
	echo "$filename"
	curl -XPOST --header 'Content-Type: application/x-ndjson' --data-binary @"$filename" 'weywot3:9200/_bulk'
done
curl -X POST "weywot3:9200/_aliases?pretty" -H 'Content-Type: application/json' -d'
{
	"actions" : [
		{ "remove" : { "index" : "*", "alias" : "'"$ALIAS"'" } },
		{ "add" : { "index" : "'"$INDEX"'", "alias" : "'"$ALIAS"'" } }
	]
}
'
