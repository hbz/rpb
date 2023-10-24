default outfile = "conf/output/bulk/bulk-rppd-${i}.ndjson";
"conf/output/test-output-rppd.json"
| open-file
| as-lines
| decode-json
| fix(FLUX_DIR + "rppd-to-lobid.fix")
| batch-reset(batchsize="1000")
| encode-json(prettyPrinting="false")
| json-to-elasticsearch-bulk(idkey="id", type="resource", index="resources-alma-fix-staging")
| write(outfile)
;
