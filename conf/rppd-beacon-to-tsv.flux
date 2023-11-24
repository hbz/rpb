// call e.g. (see transformBeacons.sh for all)
// sbt "runMain rpb.ETL conf/rppd-beacon-to-lookup.flux IN=https://persondata.toolforge.org/beacon/dewiki.txt OUT=conf/maps/gndId-to-dewiki.tsv"

IN
| open-http
| read-beacon(metadataFilter="name")
| encode-csv(includeRecordId="true", includeHeader="true", noQuotes="true", separator="\t")
| write(OUT)
;
