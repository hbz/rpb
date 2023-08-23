"http://rpb-cms-test.lobid.org/api/articles?populate=*&pagination[pageSize]=5"
| open-http
| as-records
| decode-json(recordPath="data.[*].attributes")
| fix(FLUX_DIR + "rpb-titel-to-lobid.fix")
| batch-reset(batchsize="1")
| encode-json(prettyPrinting="true")
| write(FLUX_DIR + "output/test-strapi-to-lobid-output-${i}.json")
;
