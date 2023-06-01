default outfile = "conf/output/bulk/bulk-${i}.ndjson";
"conf/output/output-strapi.ndjson"
| open-file
| as-lines
| decode-json
| fix(FLUX_DIR + "rpb.fix")
| batch-reset(batchsize="1000")
| encode-json(prettyPrinting="false")
| json-to-elasticsearch-bulk(idkey="id", type="resource", index="resources-alma-fix-staging")
| write(outfile)
;
