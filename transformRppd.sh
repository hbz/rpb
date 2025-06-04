#!/bin/bash
set -u

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/

bash transformBeacons.sh
rm etl/output/bulk/rppd/*
# Here, we used to import Allegro data:
# sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-to-strapi.flux IN_FILE=RPB-Export_HBZ_Bio.txt OUT_FILE=output-rppd-strapi.ndjson"
# sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-to-lobid.flux"
# But now we use the Strapi export:
zgrep -a '"type":"api::person.person"' etl/strapi-export.tar.gz > etl/output/rppd-export.jsonl
cp etl/output/rppd-export.jsonl ../rppd/conf/ # used in rppd for robots.txt
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/map-rppd-to-label.flux"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/map-gnd-person-to-label.flux"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-to-lobid.flux IN_FILE=rppd-export.jsonl RECORD_PATH=data"

# Indexing happens in rppd/transformAndIndexRppd.sh (lobid-gnd repo, branch 'rppd'), which calls this script
