# RPB

https://service-wiki.hbz-nrw.de/pages/viewpage.action?pageId=712998955

[![Build](https://github.com/hbz/rpb/workflows/Build/badge.svg)](https://github.com/hbz/rpb/actions?query=workflow%3ABuild)

This repo contains the RPB data transformation and the RPB web application.

## Setup

### Install metafix dependency

```bash
git clone https://github.com/metafacture/metafacture-fix.git
cd metafacture-fix
./gradlew publishToMavenLocal
cd ..
```

### Clone RPB project repo

```bash
git clone https://github.com/hbz/rpb.git
cd rpb
```

## Transformation development

### Run transformation

```bash
sbt "runMain rpb.ETL conf/rpb-test.flux"
```

### Validate output

```bash
sh validateJsonOutput.sh
```

### Create lookup table

```bash
sbt "runMain rpb.ETL conf/rpb-sw.flux"
```

### Run full transformation and indexing

Get full data at: http://lobid.org/download/rpb-gesamtexport/2022-03-11/

```bash

sh transformAndIndex.sh
```

## Web application

Start the web application:

```
sbt run
```

http://localhost:9000

## Java development

## Run tests

```bash
sbt "test-only tests.CITests"
```

## Generate Eclipse project for import

```bash
sbt "eclipse with-source=true"
```

## Reconciliation

NOTE: This section is work in progress, see [RPB-50](https://jira.hbz-nrw.de/browse/RPB-50).

### Import subset into OpenRefine

Get the full title data (if you did not run the full transformation locally before):

```bash
mkdir conf/RPB-Export_HBZ_Alles/
cd conf/RPB-Export_HBZ_Alles/
wget http://lobid.org/download/rpb-gesamtexport/2022-03-11/RPB-Export_HBZ_Tit.txt
cd ../..
```

Create the subset we want to reconcile:

```bash
sbt "runMain rpb.ETL conf/rpb-36sm.flux"
```

Create an OpenRefine project from the output file `conf/output/rpb-36sm.json`, selecting "Line-based text files" under "Parse data as".

In the "Undo / Redo" tab, click "Apply...", paste the content below, then click "Perform Operations".

```json
[
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Column 1",
    "expression": "grel:value.parseJson().get('#20 ')",
    "onError": "set-to-blank",
    "newColumnName": "20",
    "columnInsertIndex": 1,
    "description": "Create column 20 at index 1 based on column Column 1 using expression grel:value.parseJson().get('#20 ')"
  },
  {
    "op": "core/column-move",
    "columnName": "20",
    "index": 0,
    "description": "Move column 20 to position 0"
  }
]
```

You should have a project with 13835 rows, each with two columns: one with the extracted name from `#20 `, the other with the full JSON record.

Based on that, the next step will be reconciling the records with lobid-resources.

### Reconcile against lobid-resources

TODO: Set up lobid-resources reconciliation service, test basic workflow, then add other fields as additional properties for better results.
