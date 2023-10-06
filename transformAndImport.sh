#!/bin/bash
set -eu
IFS=$'\n\t'

# Notationen
sbt "runMain rpb.ETL conf/rpb-systematik-import.flux INPUT=rpb.ndjson PATH=rpb-notations HOST=localhost"
sbt "runMain rpb.ETL conf/rpb-systematik-import.flux INPUT=rpb-spatial.ndjson PATH=rpb-spatials HOST=localhost"

# Personen
sbt "runMain rpb.ETL conf/rppd-to-strapi.flux IN_FILE=RPB-Export_HBZ_Bio_Test.txt OUT_FILE=test-output-rppd.json"
sbt "runMain rpb.ETL conf/rppd-import.flux IN_FILE=test-output-rppd.json HOST=localhost"

# Normdaten
sbt "runMain rpb.ETL conf/rpb-sw-to-strapi.flux IN_FILE=RPB-Export_HBZ_SW_Test.txt OUT_FILE=test-output-sw.json"
sbt "runMain rpb.ETL conf/rpb-sw-import.flux IN_FILE=test-output-sw.json HOST=localhost"

# Titeldaten
sbt "runMain rpb.ETL conf/rpb-test-titel-to-strapi.flux"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('f36_','u') PATH=articles"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('f36_','Monografie') PATH=independent-works"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('f36_','Band') PATH=independent-works"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('f36t','MultiVolumeBook') PATH=independent-works"
