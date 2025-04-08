# BiblioVino

[![Build](https://github.com/hbz/rpb/actions/workflows/build.yml/badge.svg?branch=biblioVino)](https://github.com/hbz/rpb/actions?query=workflow%3ABuild+branch:biblioVino)

This branch of the [RPB repo](https://github.com/hbz/rpb) contains [modifications](https://github.com/hbz/rpb/compare/main...biblioVino#files_bucket) for the BiblioVino web application: https://wein.lbz-rlp.de

## Setup

Clone the repo's `biblioVino` branch into a directory called `biblioVino`:

```
git clone https://github.com/hbz/rpb.git biblioVino -b biblioVino
```

Go into that directory:

```
cd biblioVino
```

## Web application

Start the web application:

### Test mode

```
sbt run
```

### Prod mode

```
sbt stage
./target/universal/stage/bin/rpb -no-version-check
```

Open http://localhost:9000

## Java development

## Run tests

```bash
sbt "test-only tests.CITests"
```

## Generate Eclipse project for import

```bash
sbt "eclipse with-source=true"
```

