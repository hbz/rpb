#!/bin/bash
set -u

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/

rm etl/output/bulk/rppd/*
# Here, we used to import Allegro data:
# sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-to-strapi.flux IN_FILE=RPB-Export_HBZ_Bio.txt OUT_FILE=output-rppd-strapi.ndjson"
# sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-to-lobid.flux"
# Now we use the Strapi export (but contains no relations, e.g. depiction details):
zgrep -a '"type":"api::person.person","id":' etl/strapi-export.tar.gz > etl/output/rppd-export.jsonl
# Then, we add the full backup exports (like for the title data), to include depictions:
cat etl/persons.ndjson | grep '"data"' >> etl/output/rppd-export.jsonl
cp etl/output/rppd-export.jsonl ../rppd/conf/ # used in rppd for robots.txt
sbt --java-home $JAVA_HOME -mem 3000 "runMain rpb.ETL etl/rppd-to-lobid.flux IN_FILE=rppd-export.jsonl RECORD_PATH=data"

# Indexing happens in rppd/transformAndIndexRppd.sh (lobid-gnd repo, branch 'rppd'), which calls this script
