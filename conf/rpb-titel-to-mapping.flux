// cat conf/RPB-Export_HBZ_Tit.txt | grep '#983' > RPB-Export_HBZ_Tit_hbzIds.txt
// (but remove last line; grep with -a yields over 40k lines, some binary newline?)
FLUX_DIR + "RPB-Export_HBZ_Tit_hbzIds.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix("retain(f983)")
| rpb.MapAlmaToRpb
| write(FLUX_DIR + "output/output-mapping.tsv")
;
