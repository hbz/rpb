default IN_FILE = "gndId-to-rppdId.tsv"; // TODO set up smaller file for testing
default OUT_FILE = "gndId-to-depiction.tsv";
MAPS_DIR = "conf/maps/";

MAPS_DIR + IN_FILE
| open-file
| as-lines
| decode-csv(hasHeader="true", separator="\t")
| fix("retain('gndId')")
| stream-to-triples
| template("http://lobid.org/gnd/${o}.json")
| log-object("Will GET: ")
| open-http // TODO handle 404, skip
| as-records
| decode-json
| fix("
unless exists('depiction[]')
  reject()
end
retain('gndIdentifier','depiction[]')
")
| encode-csv(includeHeader="true", separator="\t")
| write(MAPS_DIR + OUT_FILE)
;
