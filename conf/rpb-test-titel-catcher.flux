default errorFix="missing76a.fix";
default outfile = "missing76a_test.txt";

FLUX_DIR + "RPB-Export_HBZ_Titel_Test.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FLUX_DIR + errorFix)
| batch-log
| encode-formeta
| write(FLUX_DIR + outfile)
;
