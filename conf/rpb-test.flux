FLUX_DIR + "RPB-Export_HBZ_Titel_Test.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FLUX_DIR + "rpb.fix")
| batch-reset(batchsize="1")
| encode-json(prettyPrinting="true")
| write(FLUX_DIR + "output/test-output-${i}.json")
;