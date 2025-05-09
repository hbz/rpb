default outfile = "etl/output/bulk/bulk-${i}.ndjson";
default url = "http://localhost:9000/";
default secret = "";
input
| open-file
| as-lines
| open-http(url=url+"?secret="+secret, method="PUT", body="@-", contentType="application/json")
| as-lines
| print
;
