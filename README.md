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

### Get the full title data

If you did not run the full transformation locally before:

```bash
mkdir conf/RPB-Export_HBZ_Alles/
cd conf/RPB-Export_HBZ_Alles/
wget http://lobid.org/download/rpb-gesamtexport/2022-03-11/RPB-Export_HBZ_Tit.txt
cd ../..
```

### RPB source data with hbz IDs

Goal: for all RPB entries with an hbz ID in `#983`, create a mapping from the hbz union catalog ID `almaMmsId` to the `rpbId` from `#00 `. With this, during the transformation of the hbz union catalog for lobid-resources, we can make sure that all entries are marked as members of RPB (`containedIn`, `rpbId`).

Create the subset we want to reconcile (all entries with `#983`):

```bash
sbt "runMain rpb.ETL conf/rpb-983.flux"
```

Create an OpenRefine project from the output file `conf/output/rpb-983.json`, selecting "Line-based text files" under "Parse data as". Optionally, limit the number of rows to import ("Load at most [ ] row(s) of data") for faster experimentation with reconciliation results.

In the "Undo / Redo" tab, click "Apply...", paste the content below, then click "Perform Operations".

```json
[
  {
    "op": "core/column-rename",
    "oldColumnName": "Column 1",
    "newColumnName": "Allegro",
    "description": "Rename column Column 1 to Allegro"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Allegro",
    "expression": "grel:value.parseJson().get('#983')",
    "onError": "set-to-blank",
    "newColumnName": "983",
    "columnInsertIndex": 1,
    "description": "Create column 983 at index 1 based on column Allegro using expression grel:value.parseJson().get('#983')"
  },
  {
    "op": "core/recon",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "columnName": "983",
    "config": {
      "mode": "standard-service",
      "service": "https://test.lobid.org/resources/reconcile",
      "identifierSpace": "https://test.lobid.org/resources",
      "schemaSpace": "http://purl.org/dc/terms/BibliographicResource",
      "type": {
        "id": "BibliographicResource",
        "name": "BibliographicResource"
      },
      "autoMatch": true,
      "columnDetails": [],
      "limit": 0
    },
    "description": "Reconcile cells in column 983 to type BibliographicResource"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "983",
    "expression": "cell.recon.match.id",
    "onError": "set-to-blank",
    "newColumnName": "almaMmsId",
    "columnInsertIndex": 2,
    "description": "Create column almaMmsId at index 2 based on column 983 using expression cell.recon.match.id"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Allegro",
    "expression": "grel:value.parseJson().get('#00 ')",
    "onError": "set-to-blank",
    "newColumnName": "rpbId",
    "columnInsertIndex": 1,
    "description": "Create column rpbId at index 1 based on column Allegro using expression grel:value.parseJson().get('#00 ')"
  },
  {
    "op": "core/column-move",
    "columnName": "rpbId",
    "index": 3,
    "description": "Move column rpbId to position 3"
  }
]
```

This reconciles the hbz IDs from `#983` with lobid-resources to add a column `almaMmsId`, as well as a column `rpbId` from `#00 `. We can now filter on the matched entries, remove the original data column and the hbz ID column, and export the remaining `almaMmsId` and `rpbId` columns as tab-separated values to be used for lookups in the lobid-resources transformation.

We currently have two output files for this workflow (in `conf/maps/`): `almaMmsId-to-rpbId.tsv`, the actual goal mapping, and `hbzIds-missing-in-alma.tsv`, a mapping of values in `#983` that were not reconciled (some look like proper hbz IDs that seem to be missing in Alma, some look like cataloging errors) to `rpbId` from `#00 `.

### RPB `#36 =sm` data w/o hbz IDs

Create the subset we want to reconcile (entries with `#36 =sm` and no hbz ID in `#983`):

```bash
sbt "runMain rpb.ETL conf/rpb-36sm.flux"
```

Create an OpenRefine project from the output file `conf/output/rpb-36sm.json`, selecting "Line-based text files" under "Parse data as". Optionally, limit the number of rows to import ("Load at most [ ] row(s) of data") for faster experimentation with reconciliation results.

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
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Column 1",
    "expression": "grel:value.parseJson().get('#19 ')",
    "onError": "set-to-blank",
    "newColumnName": "19",
    "columnInsertIndex": 2,
    "description": "Create column 19 at index 2 based on column Column 1 using expression grel:value.parseJson().get('#19 ')"
  },
  {
    "op": "core/column-move",
    "columnName": "19",
    "index": 1,
    "description": "Move column 19 to position 1"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Column 1",
    "expression": "grel:value.parseJson().get('#81 ')",
    "onError": "set-to-blank",
    "newColumnName": "81",
    "columnInsertIndex": 3,
    "description": "Create column 81 at index 3 based on column Column 1 using expression grel:value.parseJson().get('#81 ')"
  },
  {
    "op": "core/text-transform",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "columnName": "81",
    "expression": "value.replace(/.*u\\.d\\.T\\.:.*/,\"\")",
    "onError": "keep-original",
    "repeat": false,
    "repeatCount": 10,
    "description": "Text transform on cells in column 81 using expression value.replace(/.*u\\.d\\.T\\.:.*/,\"\")"
  },
  {
    "op": "core/column-move",
    "columnName": "81",
    "index": 2,
    "description": "Move column 81 to position 2"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Column 1",
    "expression": "grel:value.parseJson().get('#60 ')",
    "onError": "set-to-blank",
    "newColumnName": "60",
    "columnInsertIndex": 4,
    "description": "Create column 60 at index 4 based on column Column 1 using expression grel:value.parseJson().get('#60 ')"
  },
  {
    "op": "core/column-move",
    "columnName": "60",
    "index": 3,
    "description": "Move column 60 to position 3"
  },
  {
    "op": "core/text-transform",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "columnName": "60",
    "expression": "grel:replace(value, '_', '')",
    "onError": "keep-original",
    "repeat": false,
    "repeatCount": 10,
    "description": "Text transform on cells in column 60 using expression grel:replace(value, '_', '')"
  },
  {
    "op": "core/text-transform",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "columnName": "60",
    "expression": "grel:replace(value, 'n', '-')",
    "onError": "keep-original",
    "repeat": false,
    "repeatCount": 10,
    "description": "Text transform on cells in column 60 using expression grel:replace(value, 'n', '-')"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Column 1",
    "expression": "grel:value.parseJson().get('#39 ')",
    "onError": "set-to-blank",
    "newColumnName": "39",
    "columnInsertIndex": 5,
    "description": "Create column 39 at index 5 based on column Column 1 using expression grel:value.parseJson().get('#39 ')"
  },
  {
    "op": "core/column-move",
    "columnName": "39",
    "index": 4,
    "description": "Move column 39 to position 4"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Column 1",
    "expression": "grel:value.parseJson().get('#76b')",
    "onError": "set-to-blank",
    "newColumnName": "76b",
    "columnInsertIndex": 6,
    "description": "Create column 76b at index 6 based on column Column 1 using expression grel:value.parseJson().get('#76b')"
  },
  {
    "op": "core/column-move",
    "columnName": "76b",
    "index": 5,
    "description": "Move column 76b to position 5"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Column 1",
    "expression": "grel:value.parseJson().get('#74 ')",
    "onError": "set-to-blank",
    "newColumnName": "74",
    "columnInsertIndex": 7,
    "description": "Create column 74 at index 7 based on column Column 1 using expression grel:value.parseJson().get('#74 ')"
  },
  {
    "op": "core/column-move",
    "columnName": "74",
    "index": 6,
    "description": "Move column 74 to position 6"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Column 1",
    "expression": "grel:value.parseJson().get('#75 ')",
    "onError": "set-to-blank",
    "newColumnName": "75",
    "columnInsertIndex": 8,
    "description": "Create column 75 at index 8 based on column Column 1 using expression grel:value.parseJson().get('#75 ')"
  },
  {
    "op": "core/column-move",
    "columnName": "75",
    "index": 7,
    "description": "Move column 75 to position 7"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Column 1",
    "expression": "grel:\"http://www.rpb-rlp.de/\" + value.parseJson().get('#00 ')",
    "onError": "set-to-blank",
    "newColumnName": "rpbUrl",
    "columnInsertIndex": 9,
    "description": "Create column rpbUrl at index 9 based on column Column 1 using expression grel:\"http://www.rpb-rlp.de/\" + value.parseJson().get('#00 ')"
  },
  {
    "op": "core/column-move",
    "columnName": "rpbUrl",
    "index": 0,
    "description": "Move column rpbUrl to position 0"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "20",
    "expression": "grel:value",
    "onError": "set-to-blank",
    "newColumnName": "20-original",
    "columnInsertIndex": 2,
    "description": "Create column 20-original at index 2 based on column 20 using expression grel:value"
  },
  {
    "op": "core/column-rename",
    "oldColumnName": "20",
    "newColumnName": "lobidMatch",
    "description": "Rename column 20 to lobidMatch"
  },
  {
    "op": "core/recon",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "columnName": "lobidMatch",
    "config": {
      "mode": "standard-service",
      "service": "http://test.lobid.org/resources/reconcile",
      "identifierSpace": "http://test.lobid.org/resources",
      "schemaSpace": "http://purl.org/dc/terms/BibliographicResource",
      "type": {
        "id": "(Series OR Journal OR EditedVolume OR MultiVolumeBook OR Periodical OR Proceeding OR Newspaper OR Bibliography OR OfficialPublication OR Legislation OR Report) AND NOT (Article OR PublicationIssue)",
        "name": "Überordnungen"
      },
      "autoMatch": true,
      "columnDetails": [
        {
          "column": "19",
          "propertyName": "Ansetzungssachtitel",
          "propertyID": "_all"
        },
        {
          "column": "81",
          "propertyName": "Fußnote",
          "propertyID": "_all"
        },
        {
          "column": "60",
          "propertyName": "HE Urheber",
          "propertyID": "contribution.agent.gndIdentifier"
        },
        {
          "column": "39",
          "propertyName": "Verfasserangabe",
          "propertyID": "contribution.agent.label"
        },
        {
          "column": "76b",
          "propertyName": "Erscheinungsjahr",
          "propertyID": "publication.startDate"
        },
        {
          "column": "74",
          "propertyName": "Verlagsort",
          "propertyID": "publication.location"
        },
        {
          "column": "75",
          "propertyName": "Verlag",
          "propertyID": "publication.publishedBy"
        }
      ],
      "limit": 0
    },
    "description": "Reconcile cells in column lobidMatch to type Überordnungen"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "lobidMatch",
    "expression": "cell.recon.match.id",
    "onError": "set-to-blank",
    "newColumnName": "almaMmsId",
    "columnInsertIndex": 2,
    "description": "Create column almaMmsId at index 2 based on column lobidMatch using expression cell.recon.match.id"
  }
]
```

You should now have a project with 8138 rows, each with 9 columns: data from fields `#20 `, `#19 `, `#81 `, `#60 `, `#39 `, `#76b`, `#74 `, `#75 ` and the full JSON record. Based on that, we reconciled the `20` column, now renamed to `lobidMatch`, including data from columns `19`, `81`, `60`, `39`, `76b`, `74`, and `75`. We can now check the matched / unmatched entries in the Facet / Filter tab (to restore the facet, select the `lobidMatch` column > Reconcile > Facets > By judgement).