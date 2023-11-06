default outfile = "conf/output/bulk/rppd/bulk-rppd-${i}.jsonl"; // lobid-gnd expects *.jsonl suffix
"conf/output/output-rppd-strapi.ndjson"
| open-file
| as-lines
| decode-json
| fix(FLUX_DIR + "rppd-to-lobid.fix")
| batch-reset(batchsize="1000")
| encode-json(prettyPrinting="false")
| json-to-elasticsearch-bulk(idkey="id", type="authority", index="gnd-rppd-test")
| write(outfile)
;
