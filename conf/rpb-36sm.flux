FLUX_DIR + "RPB-Export_HBZ_Alles/RPB-Export_HBZ_Tit.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix("
unless any_equal('#36 ', 'sm')
	reject()
end
")
| encode-json(prettyPrinting="false")
| write(FLUX_DIR + "output/rpb-36sm.json")
;
