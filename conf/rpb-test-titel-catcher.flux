FLUX_DIR + "RPB-Export_HBZ_Titel_Test.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix("
if exists ('f76b')
  if exists ('f76a')
    reject()
  end
else
  reject()
end
retain('f00','f20','f76b')
")
| encode-formeta
| print
;
