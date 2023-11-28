// call e.g. (see transformBeacons.sh for all)
// sbt "runMain rpb.ETL conf/rppd-beacon-to-lookup.flux IN=https://persondata.toolforge.org/beacon/dewiki.txt OUT=conf/maps/gndId-to-dewiki.tsv"
default ENCODING = "UTF-8";
IN
| open-http(encoding=ENCODING)
| read-beacon(metadataFilter="name|institution")
| fix("
# temporary workaround until https://www.historische-kommission-muenchen-editionen.de/beacond/bsb_personen.php?beacon is fixed:
replace_all('seeAlso.url', 'https://personenlexika.digitale-sammlungen.dehttps://personenlexika.digitale-sammlungen.de', 'https://personenlexika.digitale-sammlungen.de')
unless exists('seeAlso.name')
  copy_field('seeAlso.institution', 'seeAlso.name')
end
unless exists('seeAlso.name')
  copy_field(seeAlso.url, seeAlso.name)
  replace_all(seeAlso.name, 'https?://(?:www\\\\.)?([^/]+).*', '$1')
end
retain('seeAlso.url', 'seeAlso.name')
")
| encode-csv(includeRecordId="true", includeHeader="true", noQuotes="true", separator="\t")
| write(OUT)
;
