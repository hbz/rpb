FLUX_DIR + "output/test-output-rppd.json"
| open-file
| as-lines
| decode-json
| fix(FLUX_DIR + "rppd-to-lobid.fix")
| batch-reset(batchsize="1")
| encode-json(prettyPrinting="true")
| write(FLUX_DIR + "output/test-output-rppd-lobid-${i}.json")
;