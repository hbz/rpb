#!/bin/bash
set -u

export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64/

# Get classification TTL files for lookups:
cd etl/maps
curl -O https://raw.githubusercontent.com/hbz/lbz-vocabs/main/rpb-spatial.ttl
curl -O https://raw.githubusercontent.com/hbz/lbz-vocabs/main/rpb.ttl
cd ../..

# Full GND via lobid-gnd bulk API, used for labels in RPB and RPPD:
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/map-gnd-to-label.flux"
bash filterGndMapping.sh # Filter GND mapping to only include IDs used in RPB and RPPD

# Individual beacon files, used for sameAs links in RPPD:
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://persondata.toolforge.org/beacon/dewiki.txt OUT=etl/maps/beacons/gndId-to-dewiki.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.historische-kommission-muenchen-editionen.de/beacon_adb.txt OUT=etl/maps/beacons/gndId-to-adb.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.historische-kommission-muenchen-editionen.de/beacon_ndb.txt OUT=etl/maps/beacons/gndId-to-ndb.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.lagis-hessen.de/gnd.txt OUT=etl/maps/beacons/gndId-to-lagis.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.lwl.org/westfaelische-geschichte/meta/pnd.txt OUT=etl/maps/beacons/gndId-to-lwl.tsv"
# 403 Forbidden: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.online.uni-marburg.de/fpmr/pnd.txt OUT=etl/maps/gndId-to-gesa.tsv"
# No TARGET: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.statistik-bw.de/LABI/Reichstag-Abgeordnetendatenbank.txt OUT=etl/maps/beacons/gndId-to-radb.tsv"
# No TARGET: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=http://www.andreas-praefcke.de/temp/BEACON-PND-HLS.txt OUT=etl/maps/beacons/gndId-to-hls.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=http://germania-sacra-datenbank.uni-goettingen.de/beacon.txt OUT=etl/maps/beacons/gndId-to-germania_sacra.tsv"
# Picks wrong values: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.historische-kommission-muenchen-editionen.de/beacon_adr.txt OUT=etl/maps/beacons/gndId-to-adr.tsv"
# 500 Internal Server Error: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.archinform.net/service/beacon.txt OUT=etl/maps/beacons/gndId-to-archinform.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.biographien.ac.at/oebl/oebl-beacon.txt OUT=etl/maps/beacons/gndId-to-oebl.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://persondata.toolforge.org/beacon/dewikisource_blkoe.txt OUT=etl/maps/beacons/gndId-to-blkoe.tsv"
# No TARGET: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=http://www.andreas-praefcke.de/temp/BEACON-GND-Wein.txt OUT=etl/maps/beacons/gndId-to-wein.tsv"
# No TARGET: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.statistik-bw.de/LABI/Badische-Biographien.txt OUT=etl/maps/beacons/gndId-to-babi.tsv"
# No TARGET: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=http://www.andreas-praefcke.de/temp/BEACON-GND-GDW.txt OUT=etl/maps/beacons/gndId-to-gdw.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.historische-kommission-muenchen-editionen.de/beacond/bsb_personen.php?beacon OUT=etl/maps/beacons/gndId-to-bsb.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://swblod.bsz-bw.de/beacon/beacon.sbub.txt OUT=etl/maps/beacons/gndId-to-sbub.tsv"
# UnknownHostException: beacon.findbuch.de: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=http://beacon.findbuch.de/downloads/ps_usbk/ps_usbk-pndbeacon.txt OUT=etl/maps/beacons/gndId-to-usbk.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.tripota.uni-trier.de/beacon_tripota.txt OUT=etl/maps/beacons/gndId-to-tripota.tsv ENCODING=ISO-8859-15"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://portraitindex.de/pnd_beacon.txt OUT=etl/maps/beacons/gndId-to-portraitindex.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=http://www.virtuelles-kupferstichkabinett.de/service/beacon OUT=etl/maps/beacons/gndId-to-kupferstichkabinett.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=http://www.regesta-imperii.de/fileadmin/user_upload/downloads/beacon_ri.txt OUT=etl/maps/beacons/gndId-to-ri.tsv"
# No TARGET: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=http://www.andreas-praefcke.de/temp/BEACON-PND-OstdeutscheBiographie.txt OUT=etl/maps/beacons/gndId-to-odb.tsv"
# No TARGET: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=http://www.andreas-praefcke.de/temp/BEACON-GND-OeML.txt OUT=etl/maps/beacons/gndId-to-oeml.tsv"
# "No group 4": sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://lobid.org/download/beacons/hbzlod-pndbeacon.txt OUT=etl/maps/beacons/gndId-to-hbzlod.tsv"
# Too large, filter: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=http://resolver.hebis.de/wikimedia/pndresolver/beacon.txt OUT=etl/maps/beacons/gndId-to-hebis.tsv"
# Too large, filter: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=http://www.bib-bvb.de/OpenData/beacon_bvb01.txt OUT=etl/maps/beacons/gndId-to-b3kat.tsv"
# 403 Forbidden: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.deutsche-digitale-bibliothek.de/beacon/beacon-ddb-persons.txt OUT=etl/maps/beacons/gndId-to-ddb.tsv"
# Too large, filter: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://katalog.ub.uni-heidelberg.de/beacon.txt OUT=etl/maps/beacons/gndId-to-heidi.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://persondata.toolforge.org/beacon/dewiki_commons.txt OUT=etl/maps/beacons/gndId-to-commons.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.gutenberg-biographics.ub.uni-mainz.de/gnd/personen/beacon/file.txt OUT=etl/maps/beacons/gndId-to-gutenberg.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.leo-bw.de/documents/10157/0/leo-bw-beacon_labi_personen_2016.txt OUT=etl/maps/beacons/gndId-to-leo_labi.tsv"
# Error, but looks good: sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.leo-bw.de/documents/10157/0/leo-bw-beacon_kgl_bio_2017.txt OUT=etl/maps/beacons/gndId-to-leo_kgl.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.historische-kommission-muenchen-editionen.de/beacond/vd16.txt OUT=etl/maps/beacons/gndId-to-vd16.tsv"
sbt --java-home $JAVA_HOME "runMain rpb.ETL etl/rppd-beacon-to-tsv.flux IN=https://www.regionalgeschichte.net/beacons/persons.txt OUT=etl/maps/beacons/gndId-to-regionalgeschichte.tsv"
