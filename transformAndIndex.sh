#!/bin/bash
set -eu
IFS=$'\n\t'

sbt "runMain rpb.ETL conf/rpb-sw.flux"
sbt "runMain rpb.ETL conf/rpb-titel.flux"

unset http_proxy # for posting to weywot3
for filename in conf/output/bulk/bulk-*.ndjson
do
	echo "$filename"
	curl -XPOST --header 'Content-Type: application/x-ndjson' --data-binary @"$filename" 'weywot3:9200/_bulk'
done
