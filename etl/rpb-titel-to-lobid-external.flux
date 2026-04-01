default outfile = "etl/output/bulk/bulk-${i}.ndjson";
default url = "http://localhost:9000/";
default secret = "";
input
| open-file
| as-lines
| rpb.FirstRecordOnly
| open-http(url=url+"?secret="+secret, method="PUT", body="@-", contentType="application/json")
| sleep(sleepTime="1500", timeUnit="MILLISECONDS")
| as-lines
| print
;
