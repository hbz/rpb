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
