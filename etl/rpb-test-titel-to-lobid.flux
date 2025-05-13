FLUX_DIR + "output/test-output-strapi.json"
| open-file
| as-lines
| decode-json
| fix(FLUX_DIR + "rpb-titel-to-lobid.fix")
| batch-reset(batchsize="1")
| encode-json(prettyPrinting="true")
| write(FLUX_DIR + "output/test-output-${i}.json")
;