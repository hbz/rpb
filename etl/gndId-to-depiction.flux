default IN_FILE = "gndId-to-rppdId.tsv";
default OUT_FILE = "gndId-to-depiction.tsv";
MAPS_DIR = "etl/maps/";

MAPS_DIR + IN_FILE
| open-file
| as-lines
| decode-csv(hasHeader="true", separator="\t")
| fix("retain('gndId')")
| stream-to-triples
| template("http://lobid.org/gnd/search?format=json&filter=_exists_:depiction&q=gndIdentifier:${o}")
//| log-object("Will GET: ")
| open-http
| as-records
//| log-object("GOT: ")
| decode-json(recordPath="member")
| fix("
unless exists('depiction[]')
  reject()
end
retain('gndIdentifier','depiction[]')
")
| encode-csv(includeHeader="true", separator="\t", noQuotes="true")
| write(MAPS_DIR + OUT_FILE)
;
