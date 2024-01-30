#!/bin/bash
set -eu
IFS=$'\n\t'

# Call e.g.: bash transformAndImportFull.sh test-metadaten-nrw.hbz-nrw.de

if [ -z "$@" ]; then echo "Pass host, e.g. 'localhost'"; else echo "Will import to '$@'"; fi
HOST=$1

# Notationen
# curl --request DELETE "http://$HOST:1337/api/rpb-notations/[1-5]"
sbt "runMain rpb.ETL conf/rpb-systematik-import.flux INPUT=rpb.ndjson PATH=rpb-notations HOST=$HOST"
# curl --request DELETE "http://$HOST:1337/api/rpb-spatials/[1-5]"
sbt "runMain rpb.ETL conf/rpb-systematik-import.flux INPUT=rpb-spatial.ndjson PATH=rpb-spatials HOST=$HOST"

# Personen
# curl --request DELETE "http://$HOST:1337/api/rppds/[1-5]"
sbt "runMain rpb.ETL conf/rppd-to-strapi.flux IN_FILE=RPB-Export_HBZ_Bio.txt OUT_FILE=output-rppd-strapi.ndjson"
sbt "runMain rpb.ETL conf/rppd-import.flux IN_FILE=output-rppd-strapi.ndjson HOST=$HOST"

# Normdaten
# curl --request DELETE "http://$HOST:1337/api/rpb-authorities/[1-5]"
sbt "runMain rpb.ETL conf/rpb-sw-to-strapi.flux IN_FILE=RPB-Export_HBZ_SW.txt OUT_FILE=output-sw-strapi.ndjson"
sbt "runMain rpb.ETL conf/rpb-sw-import.flux IN_FILE=output-sw-strapi.ndjson HOST=$HOST"

# Titeldaten
sbt "runMain rpb.ETL conf/rpb-titel-to-strapi.flux"
# curl --request DELETE "http://$HOST:1337/api/articles/[1-5]"
sbt "runMain rpb.ETL conf/rpb-titel-import.flux PICK=all_equal('f36_','u') PATH=articles HOST=$HOST"
# curl --request DELETE "http://$HOST:1337/api/independent-works/[1-5]"
sbt "runMain rpb.ETL conf/rpb-titel-import.flux PICK=all_equal('f36_','Monografie') PATH=independent-works HOST=$HOST"
sbt "runMain rpb.ETL conf/rpb-titel-import.flux PICK=all_equal('f36_','Band') PATH=independent-works HOST=$HOST"
sbt "runMain rpb.ETL conf/rpb-titel-import.flux PICK=all_equal('f36t','MultiVolumeBook') PATH=independent-works HOST=$HOST"
