default rpbHarvest = FLUX_DIR + "rpbHarvest.jsonl";

"Start harvesting rpb."
| print;

"http://rpb1.hbz-nrw.de:1990/resources/search?q=_exists_%3AhbzId+AND+NOT+rpbId%3Af*"
| open-http(header="User-Agent: hbz/rpb-checker", accept="application/x-jsonlines")
| as-lines
| object-batch-log("RPB API records processed: ${totalRecords}", batchSize="100")
| write(rpbHarvest)
;

rpbHarvest
| open-file
| as-lines
| decode-json
| fix(FLUX_DIR + "getHbzIdFromLobid.fix")
| encode-csv(includeHeader="TRUE", separator="\t", noQuotes="true")
| object-batch-log("PRB2CSV records processed: ${totalRecords}", batchSize="100")
| write(FLUX_DIR + "rpbWithHT.tsv")
;

"Done harvesting rpb. Start sending requests to lobid."
| print;

rpbHarvest
| open-file
| as-lines
| decode-json
| fix("replace_all('hbzId','^(.*)$','https://lobid.org/resources/search?q=hbzId%3A$1&format=jsonl')
retain('hbzId')")
| literal-to-object
| object-batch-log("HbzId2Url records processed: ${totalRecords}", batchSize="100")
| open-http(accept="application/json",header="User-Agent: hbz/rpb-checker")
| as-lines
| catch-object-exception
| decode-json
| fix(FLUX_DIR + "getHbzIdFromLobid.fix")
| encode-csv(includeHeader="TRUE", separator="\t", noQuotes="true")
| object-batch-log("Lobid Harvest records processed: ${totalRecords}", batchSize="100")
| write(FLUX_DIR + "rpbLobidMappingWithHT.tsv")
;