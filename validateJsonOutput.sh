#!/bin/sh
# Description: Tests generated JSON files against schemas
# Prerequisites: install 'ajv':$  npm install -g ajv-cli ajv-formats

set -e

ajv test -s test/rpb/schemas/resource.json -r "test/rpb/schemas/!(resource).json" -d "conf/output/*.json" -c ajv-formats --valid

echo "All tests \033[0;32mPASSED\033[0m\n"