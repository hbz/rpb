# rpb

https://service-wiki.hbz-nrw.de/pages/viewpage.action?pageId=712998955

## metafix

```
git clone git@github.com:metafacture/metafacture-fix.git -b rpb
cd metafacture-fix
./gradlew publishToMavenLocal
```

## etl

```
git clone git@github.com:hbz/rpb.git
cd rpb
sbt "runMain rpb.ETL conf/rpb-test.flux"
```

## eclipse

```
sbt "eclipse with-source=true"
```
