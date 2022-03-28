# rpb

https://service-wiki.hbz-nrw.de/pages/viewpage.action?pageId=712998955

[![Build](https://github.com/hbz/rpb/workflows/Build/badge.svg)](https://github.com/hbz/rpb/actions?query=workflow%3ABuild)

## metafix

```
git clone https://github.com/metafacture/metafacture-fix.git -b rpb
cd metafacture-fix
./gradlew publishToMavenLocal
```

## etl

```
git clone https://github.com/hbz/rpb.git
cd rpb
sbt "runMain rpb.ETL conf/rpb-sw.flux"
sbt "runMain rpb.ETL conf/rpb-test.flux"
```

## eclipse

```
sbt "eclipse with-source=true"
```
