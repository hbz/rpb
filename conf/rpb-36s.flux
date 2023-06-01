FLUX_DIR + "RPB-Export_HBZ_Tit.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix("
unless any_equal('#36 ', 's')
	reject()
end
if exists('#983')
	reject()
end
")
| encode-json(prettyPrinting="false")
| write(FLUX_DIR + "output/rpb-36s.json")
;
