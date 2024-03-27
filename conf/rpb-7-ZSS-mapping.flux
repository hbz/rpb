FLUX_DIR + "RPB-Export_HBZ_ZSS.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FLUX_DIR + "rpb-7-ZSS-mapping.fix")
| encode-json(prettyPrinting="false")
| write(FLUX_DIR + "output/zss.json")
;