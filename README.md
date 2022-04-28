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
