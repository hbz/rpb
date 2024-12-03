default IDS = FLUX_DIR + "rpbEntriesOfHebisRecords.txt";

IDS
| open-file
| as-lines
| match(pattern="^(.*)$", replacement="https://rpb.lbz-rlp.de/$1?format=json")
| open-http(accept="application/xml")
| as-records
| decode-json(recordPath="member")
| batch-reset(batchsize="1")
| encode-json(prettyPrinting="true")
| write(FLUX_DIR + "lobid-transformation/comparisonRpbRecords/rpb-hebis-records-${i}.json")
;

