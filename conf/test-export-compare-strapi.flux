// Get test data for the specified type; for each record,
// fetch the entry from Strapi, convert that to lobid, write.
FLUX_DIR + "output/test-output-strapi.json"
| open-file
| as-lines
| decode-json
| fix("
unless " + PICK + "
  reject()
end
prepend(f00_, 'https://rpb-cms-test.lobid.org/api/" + PATH + "?populate=*&filters[f00_][$eq]=')
retain(f00_)
")
| literal-to-object
| log-object("Strapi URL: ")
| open-http
| as-records
| decode-json(recordPath="data.[*].attributes")
| fix(FLUX_DIR + "rpb-titel-to-lobid.fix")
| encode-json
| write(FLUX_DIR + "output/test-lobid-output-from-strapi.json")
;

// To compare, convert test data directly to lobid, write.
FLUX_DIR + "output/test-output-strapi.json"
| open-file
| as-lines
| decode-json
| fix("
unless " + PICK + "
  reject()
end
")
| fix(FLUX_DIR + "rpb-titel-to-lobid.fix")
| encode-json
| write(FLUX_DIR + "output/test-lobid-output-from-file.json")
;
