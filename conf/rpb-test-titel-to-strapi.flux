FLUX_DIR + "RPB-Export_HBZ_Titel_Test.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FLUX_DIR + "rpb-titel-to-strapi.fix")
| encode-json(prettyPrinting="false")
| write(FLUX_DIR + "output/test-output-strapi.json")
;