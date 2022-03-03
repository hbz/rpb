default outfile = "bulk.ndjson";
FLUX_DIR + "RPB-Export_HBZ_Titel_Test.txt";
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FLUX_DIR + "rpb.fix")
| batch-reset(batchsize="1000")
| encode-json(prettyPrinting="true")
| json-to-elasticsearch-bulk(idkey="id", type="resource", index="resources-smalltest")
| write(outfile)
;

// then upload via curl:
//curl -XPOST --header 'Content-Type: application/x-ndjson' --data-binary @bulk.ndjson 'http://weywot3.hbz-nrw.de:9200/_bulk'
