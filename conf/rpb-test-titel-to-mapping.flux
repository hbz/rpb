FIX = "
unless exists (f983)
    reject()
end
copy_field('f983','_id')
retain(f983, f00_, _id)
";

FLUX_DIR + "RPB-Export_HBZ_Titel_Test.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FIX)
| stream-to-triples(redirect="true")
| @X;

FLUX_DIR + "RPB-Export_HBZ_Titel_Test.txt"
| open-file(encoding="IBM437")
| as-lines
| rpb.Decode
| fix(FIX)
| stream-to-triples(redirect="true")
| template("https://lobid.org/resources/${o}")
| open-http
| as-records
| filter-strings("Not found:", passMatches="false")
| decode-json
| fix("
copy_field(hbzId, _id)
retain(almaMmsId, _id)
")
| stream-to-triples(redirect="true")
| @X;

@X
| wait-for-inputs("2")
| sort-triples(by="subject")
| collect-triples
| fix("
prepend(f00_, 'RPB')
paste(mapping, almaMmsId, f00_, join_char: '\t')
retain(mapping)
")
| stream-to-triples
| template("${o}")
| write(FLUX_DIR + "output/test-output-mapping.tsv")
;
