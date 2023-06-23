# RPB

https://service-wiki.hbz-nrw.de/pages/viewpage.action?pageId=712998955

[![Build](https://github.com/hbz/rpb/workflows/Build/badge.svg)](https://github.com/hbz/rpb/actions?query=workflow%3ABuild)

This repo contains the RPB data transformation and the RPB web application.

## Setup

### Install metafacture dependencies

See `.github/workflows/build.yml`.

### Clone RPB project repo

```bash
git clone https://github.com/hbz/rpb.git
cd rpb
```

## Transformation development

### Create lookup table

```bash
sbt "runMain rpb.ETL conf/rpb-test-sw.flux"
```

This writes a `.tsv` file to `output/`, to be used for lookups in the transformation.

### Run transformation to strapi data

```bash
sbt "runMain rpb.ETL conf/rpb-test-titel-to-strapi.flux"
```

This writes a single `.json` files to `output/` (it's actually JSON lines, but the suffix makes it work with JSON tools, e.g. for syntax coloring and formatting).

### Import strapi data

```bash
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('f36_','u') PATH=articles"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('f36_','s') PATH=books"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('f36_','sbd') PATH=books"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=exists('f36t') PATH=multi-volume-books"
sbt "runMain rpb.ETL conf/rpb-test-titel-import.flux PICK=all_equal('f36_','sm') PATH=periodicals"
```

This attempts to import all data selected with the `PICK` variable to the API endpoint in `PATH`, and prints the server response.

### Run transformation to lobid data

```bash
sbt "runMain rpb.ETL conf/rpb-test-titel-to-lobid.flux"
```

This writes individual `.json` files for each record in the input data to `output/`.


### Validate output

Prerequisites: `npm install -g ajv-cli ajv-formats`

```bash
sh validateJsonOutput.sh
```

This validates the resulting files against the JSON schemas in `test/rpb/schemas/`.

### Index creation

If you're not indexing into an existing lobid-resources index, make sure to create one with the proper index settings, e.g. to create `resources-rpb-20230623` from `quaoar3`:

```bash
unset http_proxy # for putting on weywot
sol@quaoar3:~/git/rpb$ curl -XPUT -H "Content-Type: application/json" weywot5:9200/resources-rpb-20230623?pretty -d @../lobid-resources/src/main/resources/alma/index-config.json
```

For testing, the real index name (e.g. `resources-rpb-20230623`) is aliased by `resources-rpb-test`, which is used by https://test.lobid.org/resources / http://test.rpb.lobid.org and in the transformation.

### Run full transformation and indexing

Get full data at: http://lobid.org/download/rpb-gesamtexport/, place files in `conf/`.

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

NOTE: This section is based on the work-in-progress reconciliation service in [lobid-resources](https://github.com/hbz/lobid-resources/pull/1777).

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
    "columnInsertIndex": 0,
    "description": "Create column 20 at index 0 based on column Column 1 using expression grel:value.parseJson().get('#20 ')"
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
    "columnInsertIndex": 1,
    "description": "Create column 19 at index 1 based on column Column 1 using expression grel:value.parseJson().get('#19 ')"
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
    "columnInsertIndex": 2,
    "description": "Create column 60 at index 2 based on column Column 1 using expression grel:value.parseJson().get('#60 ')"
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
    "columnInsertIndex": 3,
    "description": "Create column 39 at index 3 based on column Column 1 using expression grel:value.parseJson().get('#39 ')"
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
    "columnInsertIndex": 4,
    "description": "Create column 76b at index 4 based on column Column 1 using expression grel:value.parseJson().get('#76b')"
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
    "columnInsertIndex": 5,
    "description": "Create column 74 at index 5 based on column Column 1 using expression grel:value.parseJson().get('#74 ')"
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
    "columnInsertIndex": 6,
    "description": "Create column 75 at index 6 based on column Column 1 using expression grel:value.parseJson().get('#75 ')"
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
    "columnInsertIndex": 0,
    "description": "Create column rpbUrl at index 0 based on column Column 1 using expression grel:\"http://www.rpb-rlp.de/\" + value.parseJson().get('#00 ')"
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
        "id": "(Series OR Journal OR EditedVolume OR MultiVolumeBook OR Periodical OR Bibliography) AND NOT (Article OR PublicationIssue)",
        "name": "Überordnungen"
      },
      "autoMatch": true,
      "columnDetails": [
        {
          "column": "19",
          "propertyName": "Ansetzungssachtitel",
          "propertyID": "alternativeTitle"
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
          "column": "76b",
          "propertyName": "Erscheinungsverlauf",
          "propertyID": "publication.publicationHistory"
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

The resulting matches can be exported (for comparing reconciliation with different settings etc.): Export -> Templating..., Row template: `{{cells["almaMmsId"].value}}`.

You should now have a project with 8138 rows, each with 8 columns: data from fields `#20 `, `#19 `, `#60 `, `#39 `, `#76b`, `#74 `, `#75 ` and the full JSON record. Based on that, we reconciled the `20` column, now renamed to `lobidMatch`, including data from columns `19`, `60`, `39`, `76b`, `74`, and `75`. We can now check the matched / unmatched entries in the Facet / Filter tab (to restore the facet, select the `lobidMatch` column > Reconcile > Facets > By judgement).

After we're done with any manual matching, we can prepare the data for the resulting mapping of `almaMmsId` to `rpbId`:

```json
[
  {
    "op": "core/column-removal",
    "columnName": "almaMmsId",
    "description": "Remove column almaMmsId"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "record-based"
    },
    "baseColumnName": "lobidMatch",
    "expression": "cell.recon.match.id",
    "onError": "set-to-blank",
    "newColumnName": "almaMmsId",
    "columnInsertIndex": 2,
    "description": "Create column almaMmsId at index 2 based on column lobidMatch using expression cell.recon.match.id"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [
        {
          "type": "list",
          "name": "almaMmsId",
          "expression": "isBlank(value)",
          "columnName": "almaMmsId",
          "invert": false,
          "omitBlank": false,
          "omitError": false,
          "selection": [
            {
              "v": {
                "v": false,
                "l": "false"
              }
            }
          ],
          "selectBlank": false,
          "selectError": false
        }
      ],
      "mode": "row-based"
    },
    "baseColumnName": "Column 1",
    "expression": "grel:\"RPB\" + value.parseJson().get(\"#00 \")",
    "onError": "set-to-blank",
    "newColumnName": "rpbId",
    "columnInsertIndex": 3,
    "description": "Create column rpbId at index 3 based on column Column 1 using expression grel:\"RPB\" + value.parseJson().get(\"#00 \")"
  }
]
```

The final result can then be exported (Export -> Custom tabular exporter) to a *.tsv file with two columns mapping `almaMmsId` to `rpbId`, to be used in the union catalog transformation to add the `rpbId` value for each `almaMmsId`.

### RPB `#36 =s` data w/o hbz IDs

NOTE: This section is work in progress, see [RPB-51](https://jira.hbz-nrw.de/browse/RPB-51).

Create the subset we want to reconcile (entries with `#36 =s` and no hbz ID in `#983`):

```bash
sbt "runMain rpb.ETL conf/rpb-36s.flux"
```

Create an OpenRefine project from the output file `conf/output/rpb-36s.json`, selecting "Line-based text files" under "Parse data as". Since the full data is relatively large, limit the number of rows to import ("Load at most [ ] row(s) of data") for faster experimentation with reconciliation results.

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
    "columnInsertIndex": 0,
    "description": "Create column 20 at index 0 based on column Column 1 using expression grel:value.parseJson().get('#20 ')"
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
    "columnInsertIndex": 1,
    "description": "Create column 19 at index 1 based on column Column 1 using expression grel:value.parseJson().get('#19 ')"
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
    "columnInsertIndex": 2,
    "description": "Create column 60 at index 2 based on column Column 1 using expression grel:value.parseJson().get('#60 ')"
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
    "columnInsertIndex": 3,
    "description": "Create column 39 at index 3 based on column Column 1 using expression grel:value.parseJson().get('#39 ')"
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
    "columnInsertIndex": 4,
    "description": "Create column 76b at index 4 based on column Column 1 using expression grel:value.parseJson().get('#76b')"
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
    "columnInsertIndex": 5,
    "description": "Create column 74 at index 5 based on column Column 1 using expression grel:value.parseJson().get('#74 ')"
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
    "columnInsertIndex": 6,
    "description": "Create column 75 at index 6 based on column Column 1 using expression grel:value.parseJson().get('#75 ')"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Column 1",
    "expression": "grel:value.parseJson().get('#27 ')",
    "onError": "set-to-blank",
    "newColumnName": "27",
    "columnInsertIndex": 7,
    "description": "Create column 27 at index 7 based on column Column 1 using expression grel:value.parseJson().get('#27 ')"
  },
  {
    "op": "core/column-addition",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "baseColumnName": "Column 1",
    "expression": "grel:value.parseJson().get('#85 ')",
    "onError": "set-to-blank",
    "newColumnName": "85",
    "columnInsertIndex": 8,
    "description": "Create column 85 at index 8 based on column Column 1 using expression grel:value.parseJson().get('#85 ')"
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
    "columnInsertIndex": 0,
    "description": "Create column rpbUrl at index 0 based on column Column 1 using expression grel:\"http://www.rpb-rlp.de/\" + value.parseJson().get('#00 ')"
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
    "op": "core/text-transform",
    "engineConfig": {
      "facets": [],
      "mode": "row-based"
    },
    "columnName": "lobidMatch",
    "expression": "grel:if(cells[\"27\"].value == null, value, cells[\"27\"].value + \" \" + value)",
    "onError": "keep-original",
    "repeat": false,
    "repeatCount": 10,
    "description": "Text transform on cells in column lobidMatch using expression grel:if(cells[\"27\"].value == null, value, cells[\"27\"].value + \" \" + value)"
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
        "id": "Book AND NOT (Series OR Journal OR EditedVolume OR MultiVolumeBook OR Periodical OR Bibliography OR Article OR PublicationIssue)",
        "name": "Monographie"
      },
      "autoMatch": true,
      "columnDetails": [
        {
          "column": "19",
          "propertyName": "Ansetzungssachtitel",
          "propertyID": "alternativeTitle"
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
          "column": "76b",
          "propertyName": "Erscheinungsverlauf",
          "propertyID": "publication.publicationHistory"
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
        },
        {
          "column": "85",
          "propertyName": "Serie",
          "propertyID": "_all"
        }
      ],
      "limit": 0
    },
    "description": "Reconcile cells in column lobidMatch to type Monographie"
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

The resulting matches can be exported (for comparing reconciliation with different settings etc.): Export -> Templating..., Row template: `{{cells["almaMmsId"].value}}`.
