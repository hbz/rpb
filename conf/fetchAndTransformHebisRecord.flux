default IDS = FLUX_DIR + "hebisTestIds.txt";
createEndTime = "1"; //needed for lobid transformation

IDS
| open-file
| as-lines
| match(pattern="^(.*)$", replacement="http://sru.hebis.de/sru/DB=2.1?query=pica.ppn+%3D+%22$1%22&version=1.1&operation=searchRetrieve&stylesheet=http%3A%2F%2Fsru.hebis.de%2Fsru%2F%3Fxsl%3DsearchRetrieveResponse&recordSchema=marc21&maximumRecords=10&startRecord=1&recordPacking=xml&sortKeys=LST_Y%2Cpica%2C0%2C%2C")
| open-http(accept="application/xml")
| decode-xml
| handle-marcxml
| fix(FLUX_DIR + "lobid-transformation/marcToLobid.fix",*)
| batch-reset(batchsize="1")
| encode-json(prettyPrinting="true")
| write(FLUX_DIR + "output/test-hebis-to-lobid-output-${i}.json")
;
