#!/bin/bash
set -eu
IFS=$'\n\t'

# Call e.g.: bash transformAndImportTest.sh test-metadaten-nrw.hbz-nrw.de

if [ -z "$@" ]; then echo "Pass host, e.g. 'localhost'"; else echo "Will import to '$@'"; fi
HOST=$1
# Create token in Strapi admin UI (Settings > API Tokens), set here or in environment
API_TOKEN=$API_TOKEN

# Notationen
# curl --request DELETE "http://$HOST:1337/api/rpb-notations/[1-5]"
sbt "runMain rpb.ETL conf/rpb-systematik-import.flux INPUT=rpb.ndjson PATH=rpb-notations HOST=$HOST API_TOKEN=$API_TOKEN"
# curl --request DELETE "http://$HOST:1337/api/rpb-spatials/[1-5]"
sbt "runMain rpb.ETL conf/rpb-systematik-import.flux INPUT=rpb-spatial.ndjson PATH=rpb-spatials HOST=$HOST API_TOKEN=$API_TOKEN"
# curl --request DELETE "http://$HOST:1337/api/fachgebiete/[1-5]"
sbt "runMain rpb.ETL conf/rpb-systematik-import.flux INPUT=rpb-fachgebiete.ndjson PATH=fachgebiete HOST=$HOST API_TOKEN=$API_TOKEN"

# Personen
# curl --request DELETE "http://$HOST:1337/api/persons/[1-5]"
sbt "runMain rpb.ETL conf/rppd-to-strapi.flux IN_FILE=RPB-Export_HBZ_Bio_Test.txt OUT_FILE=test-output-rppd.json"
sbt "runMain rpb.ETL conf/rppd-import.flux IN_FILE=test-output-rppd.json HOST=$HOST API_TOKEN=$API_TOKEN"

# Normdaten
# curl --request DELETE "http://$HOST:1337/api/rpb-authorities/[1-5]"
sbt "runMain rpb.ETL conf/rpb-sw-to-strapi.flux IN_FILE=RPB-Export_HBZ_SW_Test.txt OUT_FILE=test-output-sw.json"
sbt "runMain rpb.ETL conf/rpb-sw-import.flux IN_FILE=test-output-sw.json HOST=$HOST API_TOKEN=$API_TOKEN"

# Titeldaten
sbt "runMain rpb.ETL conf/rpb-test-titel-to-strapi.flux"
# curl --request DELETE "http://$HOST:1337/api/articles/[1-5]"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('type','u') PATH=articles HOST=$HOST API_TOKEN=$API_TOKEN"
# curl --request DELETE "http://$HOST:1337/api/independent-works/[1-5]"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('type','Monografie') PATH=independent-works HOST=$HOST API_TOKEN=$API_TOKEN"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('type','Band') PATH=independent-works HOST=$HOST API_TOKEN=$API_TOKEN"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_contain('type','Mehrt') PATH=independent-works HOST=$HOST API_TOKEN=$API_TOKEN"
