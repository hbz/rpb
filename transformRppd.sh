#!/bin/bash
set -u

bash transformBeacons.sh
rm conf/output/bulk/rppd/*
sbt "runMain rpb.ETL conf/rppd-to-strapi.flux IN_FILE=RPB-Export_HBZ_Bio.txt OUT_FILE=output-rppd-strapi.ndjson"
sbt "runMain rpb.ETL conf/rppd-to-gnd-mapping.flux"
sbt "runMain rpb.ETL conf/rppd-rppdId-with-label-map.flux"
sbt "runMain rpb.ETL conf/rppd-to-lobid.flux"
# Or from Strapi export:
# zgrep -a '"type":"api::person.person"' conf/strapi-export.tar.gz > conf/output/rppd-export.jsonl
# sbt "runMain rpb.ETL conf/rppd-to-lobid.flux IN_FILE=rppd-export.jsonl RECORD_PATH=data"

# Indexing happens in rppd/transformAndIndexRppd.sh (lobid-gnd repo, branch 'rppd'), which calls this script
