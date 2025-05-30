FLUX_DIR + "RPB-Export_HBZ_Titel_Test.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix("
unless exists (f983)
  reject()
end
retain(f983)
")
| rpb.MapAlmaToRpb
| write(FLUX_DIR + "output/test-output-mapping.tsv")
;
