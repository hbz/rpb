SRUQUERRY = "http://sru.hebis.de/sru/DB=2.1?query=pica.ort+%3D+%22Mainz%22+and+pica.ppn+%3D+%22524204101%22&version=1.1&operation=searchRetrieve&stylesheet=http%3A%2F%2Fsru.hebis.de%2Fsru%2F%3Fxsl%3DsearchRetrieveResponse&recordSchema=marc21&maximumRecords=10&startRecord=1&recordPacking=xml&sortKeys=LST_Y%2Cpica%2C0%2C%2C";

SRUQUERRY
| open-http(accept="application/xml")
| decode-xml
| handle-marcxml
| fix("nothing()")
| encode-json(prettyPrinting="true")
| print
;