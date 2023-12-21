#!/bin/bash
set -eu

bash transformBeacons.sh
rm conf/output/bulk/rppd/*
sbt "runMain rpb.ETL conf/rppd-to-strapi.flux IN_FILE=RPB-Export_HBZ_Bio.txt OUT_FILE=output-rppd-strapi.ndjson"
sbt "runMain rpb.ETL conf/rppd-to-gnd-mapping.flux"
sbt "runMain rpb.ETL conf/rppd-rppdId-with-label-map.flux"
sbt "runMain rpb.ETL conf/rppd-to-lobid.flux"

# Indexing happens in rppd/transformAndIndexRppd.sh (lobid-gnd repo, branch 'rppd'), which calls this script
