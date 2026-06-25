default rpbFile = FLUX_DIR + "rpbWithHT.tsv";
default lobidFile = FLUX_DIR + "rpbLobidMappingWithHT.tsv";


// Check for duplicates

rpbFile
| open-file
| as-lines
| decode-csv(separator="\t", hasHeader="true")
| fix(FLUX_DIR + "rpbId.fix")
| stream-to-triples(redirect="true")
| sort-triples(by="all")
| collect-triples
| fix(FLUX_DIR + "rpbId2.fix")
| encode-csv(includeHeader="TRUE", separator="\t", noQuotes="true")
| write(FLUX_DIR + "duplicateHbzIdInRpb.tsv")
;

// Check for not existing hbzIds

rpbFile
| open-file
| as-lines
| decode-csv(separator="\t", hasHeader="true")
| fix(FLUX_DIR + "keepHbzIdsWithoutNZRecord.fix",*)
| encode-csv(includeHeader="TRUE", separator="\t", noQuotes="true")
| write(FLUX_DIR + "nonExistingHbzIdInRpb.tsv")
;

// Create map for all rpbIds with with non duplicate entries

rpbFile
| open-file
| as-lines
| decode-csv(separator="\t", hasHeader="true")
| fix(FLUX_DIR + "rpbId.fix")
| stream-to-triples(redirect="true")
| sort-triples(by="all")
| collect-triples
| fix(FLUX_DIR + "rpbIdSingeEntry.fix")
| fix(FLUX_DIR + "keepHbzIdsWithNZRecord.fix",*)
| encode-csv(includeHeader="TRUE", separator="\t", noQuotes="true")
| write(FLUX_DIR + "trueRpbIdNZMapping.tsv")
;

//// Create map for biblioVinoRevords with with non duplicate entries
//
//FLUX_DIR + "trueRpbIdNZMapping.tsv"
//| open-file
//| as-lines
//| filter-strings("RPB.*?t",passmatches="true")
//| write(FLUX_DIR + "trueRpbIdNZMapping_onlyRpb.tsv")
//;
//
//// Create map for rpb records with with non duplicate entries
//
//FLUX_DIR + "trueRpbIdNZMapping.tsv"
//| open-file
//| as-lines
//| filter-strings("RPB.*?w",passmatches="true")
//| write(FLUX_DIR + "trueRpbIdNZMapping_onlyWein.tsv")
//;
