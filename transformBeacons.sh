#!/bin/bash
set -eu

sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://persondata.toolforge.org/beacon/dewiki.txt OUT=conf/maps/beacons/gndId-to-dewiki.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.historische-kommission-muenchen-editionen.de/beacon_adb.txt OUT=conf/maps/beacons/gndId-to-adb.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.historische-kommission-muenchen-editionen.de/beacon_ndb.txt OUT=conf/maps/beacons/gndId-to-ndb.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.lagis-hessen.de/gnd.txt OUT=conf/maps/beacons/gndId-to-lagis.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.lwl.org/westfaelische-geschichte/meta/pnd.txt OUT=conf/maps/beacons/gndId-to-lwl.tsv"
# 403 Forbidden: sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.online.uni-marburg.de/fpmr/pnd.txt OUT=conf/maps/gndId-to-gesa.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.statistik-bw.de/LABI/Reichstag-Abgeordnetendatenbank.txt OUT=conf/maps/beacons/gndId-to-radb.tsv"
# No TARGET: sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=http://www.andreas-praefcke.de/temp/BEACON-PND-HLS.txt OUT=conf/maps/beacons/gndId-to-hls.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=http://germania-sacra-datenbank.uni-goettingen.de/beacon.txt OUT=conf/maps/beacons/gndId-to-germania_sacra.tsv"
# Picks wrong values: sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.historische-kommission-muenchen-editionen.de/beacon_adr.txt OUT=conf/maps/beacons/gndId-to-adr.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.archinform.net/service/beacon.txt OUT=conf/maps/beacons/gndId-to-archinform.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.biographien.ac.at/oebl/oebl-beacon.txt OUT=conf/maps/beacons/gndId-to-oebl.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://persondata.toolforge.org/beacon/dewikisource_blkoe.txt OUT=conf/maps/beacons/gndId-to-blkoe.tsv"
# No TARGET: sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=http://www.andreas-praefcke.de/temp/BEACON-GND-Wein.txt OUT=conf/maps/beacons/gndId-to-wein.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.statistik-bw.de/LABI/Badische-Biographien.txt OUT=conf/maps/beacons/gndId-to-babi.tsv"
# No TARGET: sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=http://www.andreas-praefcke.de/temp/BEACON-GND-GDW.txt OUT=conf/maps/beacons/gndId-to-gdw.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.historische-kommission-muenchen-editionen.de/beacond/bsb_personen.php?beacon OUT=conf/maps/beacons/gndId-to-bsb.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://swblod.bsz-bw.de/beacon/beacon.sbub.txt OUT=conf/maps/beacons/gndId-to-sbub.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=http://beacon.findbuch.de/downloads/ps_usbk/ps_usbk-pndbeacon.txt OUT=conf/maps/beacons/gndId-to-usbk.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.tripota.uni-trier.de/beacon_tripota.txt OUT=conf/maps/beacons/gndId-to-tripota.tsv ENCODING=ISO-8859-15"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://portraitindex.de/pnd_beacon.txt OUT=conf/maps/beacons/gndId-to-portraitindex.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=http://www.virtuelles-kupferstichkabinett.de/service/beacon OUT=conf/maps/beacons/gndId-to-kupferstichkabinett.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=http://www.regesta-imperii.de/fileadmin/user_upload/downloads/beacon_ri.txt OUT=conf/maps/beacons/gndId-to-ri.tsv"
# No TARGET: sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=http://www.andreas-praefcke.de/temp/BEACON-PND-OstdeutscheBiographie.txt OUT=conf/maps/beacons/gndId-to-odb.tsv"
# No TARGET: sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=http://www.andreas-praefcke.de/temp/BEACON-GND-OeML.txt OUT=conf/maps/beacons/gndId-to-oeml.tsv"
# "No group 4": sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://lobid.org/download/beacons/hbzlod-pndbeacon.txt OUT=conf/maps/beacons/gndId-to-hbzlod.tsv"
# Too large, filter: sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=http://resolver.hebis.de/wikimedia/pndresolver/beacon.txt OUT=conf/maps/beacons/gndId-to-hebis.tsv"
# Too large, filter: sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=http://www.bib-bvb.de/OpenData/beacon_bvb01.txt OUT=conf/maps/beacons/gndId-to-b3kat.tsv"
# 403 Forbidden: sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.deutsche-digitale-bibliothek.de/beacon/beacon-ddb-persons.txt OUT=conf/maps/beacons/gndId-to-ddb.tsv"
# Too large, filter: sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://katalog.ub.uni-heidelberg.de/beacon.txt OUT=conf/maps/beacons/gndId-to-heidi.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://persondata.toolforge.org/beacon/dewiki_commons.txt OUT=conf/maps/beacons/gndId-to-commons.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.gutenberg-biographics.ub.uni-mainz.de/gnd/personen/beacon/file.txt OUT=conf/maps/beacons/gndId-to-gutenberg.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.leo-bw.de/documents/10157/0/leo-bw-beacon_labi_personen_2016.txt OUT=conf/maps/beacons/gndId-to-leo_labi.tsv"
# Error, but looks good: sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.leo-bw.de/documents/10157/0/leo-bw-beacon_kgl_bio_2017.txt OUT=conf/maps/beacons/gndId-to-leo_kgl.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.historische-kommission-muenchen-editionen.de/beacond/vd16.txt OUT=conf/maps/beacons/gndId-to-vd16.tsv"
sbt "runMain rpb.ETL conf/rppd-beacon-to-tsv.flux IN=https://www.regionalgeschichte.net/beacons/persons.txt OUT=conf/maps/beacons/gndId-to-regionalgeschichte.tsv"