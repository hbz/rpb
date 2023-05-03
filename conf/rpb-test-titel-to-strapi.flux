FLUX_DIR + "RPB-Export_HBZ_Titel_Test.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| encode-json(prettyPrinting="false")
| write(FLUX_DIR + "output/test-output-strapi.json")
;