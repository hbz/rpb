default errorFix="missing76a.fix";
default outfile = "missing76a.txt";


FLUX_DIR + "RPB-Export_HBZ_Tit.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FLUX_DIR + errorFix)
| batch-log
| encode-formeta
| write(FLUX_DIR + outfile)
;
