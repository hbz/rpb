default dynamicMapPath ="./maps/";

FLUX_DIR + "output/single-strapi-to-lobid-input.json"
| open-file
| as-lines
| decode-json
| fix(FLUX_DIR + "rpb-titel-to-lobid.fix",*)
| batch-reset(batchsize="1")
| encode-json(prettyPrinting="true")
| write(FLUX_DIR + "output/single-strapi-to-lobid-output.json")
;
