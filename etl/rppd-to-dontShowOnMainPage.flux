default IN_FILE = "RPB-Export_HBZ_Bio.txt";
default OUT_FILE = "rppd-dontShowOnMainPage.json";

// use output as value for dontShowOnMainPage in rppd's application.conf:
// https://github.com/hbz/lobid-gnd/blob/rppd/conf/application.conf#L6

FLUX_DIR + IN_FILE
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix("
unless exists('f15_')
  reject()
end
retain('f82b')
")
| stream-to-triples
| template("\"${o}\"")
| write(FLUX_DIR + "output/" + OUT_FILE, header="[", separator=",", footer="]")
;
