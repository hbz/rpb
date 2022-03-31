# rpb

https://service-wiki.hbz-nrw.de/pages/viewpage.action?pageId=712998955

[![Build](https://github.com/hbz/rpb/workflows/Build/badge.svg)](https://github.com/hbz/rpb/actions?query=workflow%3ABuild)

## metafix

```bash
git clone https://github.com/metafacture/metafacture-fix.git -b rpb
cd metafacture-fix
./gradlew publishToMavenLocal
```

## etl

```bash
git clone https://github.com/hbz/rpb.git
cd rpb
sbt "runMain rpb.ETL conf/rpb-sw.flux"
sbt "runMain rpb.ETL conf/rpb-test.flux"
```

## validate

```bash
sh validateJsonOutput.sh
```

## index

```bash
sbt "runMain rpb.ETL conf/rpb2lobid.flux"
curl -XPOST --header 'Content-Type: application/x-ndjson' --data-binary @bulk.ndjson 'weywot3:9200/_bulk'
```

## eclipse

```bash
sbt "eclipse with-source=true"
```
