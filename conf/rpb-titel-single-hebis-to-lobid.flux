FLUX_DIR + "output/single-hebis-to-lobid-input.xml"
| open-file
| decode-xml
| handle-marcxml
| fix(FLUX_DIR + "hebisMarc2lobid-transformation/marcToLobid.fix", *)
| batch-reset(batchsize="1")
| encode-json(prettyPrinting="true")
| write(FLUX_DIR + "output/single-hebis-to-lobid-output.json")
;
