default outfile = "conf/output/bulk/bulk-${i}.ndjson";
default index = "resources-rpb-test";
"conf/output/output-strapi.ndjson"
| open-file
| as-lines
| decode-json
| fix(FLUX_DIR + "rpb-titel-to-lobid.fix")
| batch-reset(batchsize="1000")
| encode-json(prettyPrinting="false")
| json-to-elasticsearch-bulk(idkey="id", type="resource", index=index)
| write(outfile)
;
