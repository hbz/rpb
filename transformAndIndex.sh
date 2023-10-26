#!/bin/bash
set -eu
IFS=$'\n\t'

# Get the daily Allegro dump:
cd conf
wget https://rpb.lbz-rlp.de/rpb04/intern/RPBEXP.ZIP
unzip -o RPBEXP.ZIP
mv RPBEXP.ZIP RPBEXP/RPBEXP-$(date "+%Y%m%d-%H%M").ZIP
cd ..

# Transform the data:
sbt "runMain rpb.ETL conf/rpb-sw.flux"
sbt "runMain rpb.ETL conf/rpb-titel-to-strapi.flux"
sbt "runMain rpb.ETL conf/rpb-titel-to-lobid.flux"

# Index to Elasticsearch:
unset http_proxy # for posting to weywot3
for filename in conf/output/bulk/bulk-*.ndjson
do
	echo "$filename"
	curl -XPOST --header 'Content-Type: application/x-ndjson' --data-binary @"$filename" 'weywot3:9200/_bulk'
done
