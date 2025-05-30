// call e.g. (see transformBeacons.sh for all)
// sbt "runMain rpb.ETL etl/rppd-beacon-to-lookup.flux IN=https://persondata.toolforge.org/beacon/dewiki.txt OUT=etl/maps/gndId-to-dewiki.tsv"
default ENCODING = "UTF-8";
IN
| open-http(encoding=ENCODING)
| read-beacon(metadataFilter=".*")
| fix("
# temporary workaround until https://www.historische-kommission-muenchen-editionen.de/beacond/bsb_personen.php?beacon is fixed:
replace_all('seeAlso.url', 'https://personenlexika.digitale-sammlungen.dehttps://personenlexika.digitale-sammlungen.de', 'https://personenlexika.digitale-sammlungen.de')

vacuum() # remove empty fields

# for the name label we try, in that order: name, message, description, institution, domain:
unless exists('seeAlso.name')
  copy_field('seeAlso.message', 'seeAlso.name')
end
unless exists('seeAlso.name')
  copy_field('seeAlso.description', 'seeAlso.name')
end
unless exists('seeAlso.name')
  copy_field('seeAlso.institution', 'seeAlso.name')
end
unless exists('seeAlso.name')
  copy_field(seeAlso.url, seeAlso.name)
  replace_all(seeAlso.name, 'https?://(?:www\\\\.)?([^/]+).*', '$1')
end

replace_all(seeAlso.name, ' +', ' ')

retain('seeAlso.url', 'seeAlso.name')
")
| encode-csv(includeRecordId="true", includeHeader="true", noQuotes="true", separator="\t")
| write(OUT)
;
