FLUX_DIR + "RPB-Export_HBZ_Tit.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix("
unless exists('#983')
	reject()
end
")
| encode-json(prettyPrinting="false")
| write(FLUX_DIR + "output/rpb-983.json")
;
