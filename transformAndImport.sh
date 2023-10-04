#!/bin/bash
set -eu
IFS=$'\n\t'

# Notationen
sbt "runMain rpb.ETL conf/rpb-systematik-import.flux INPUT=rpb.ndjson PATH=rpb-notations"
sbt "runMain rpb.ETL conf/rpb-systematik-import.flux INPUT=rpb-spatial.ndjson PATH=rpb-spatials"

# Personen
sbt "runMain rpb.ETL conf/rppd-to-strapi.flux"
sbt "runMain rpb.ETL conf/rppd-import.flux"

# Normdaten
sbt "runMain rpb.ETL conf/rpb-sw-to-strapi.flux"
sbt "runMain rpb.ETL conf/rpb-sw-import.flux"

# Titeldaten
sbt "runMain rpb.ETL conf/rpb-test-titel-to-strapi.flux"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('f36_','u') PATH=articles"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('f36_','Monografie') PATH=independent-works"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('f36_','Band') PATH=independent-works"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('f36t','MultiVolumeBook') PATH=independent-works"
