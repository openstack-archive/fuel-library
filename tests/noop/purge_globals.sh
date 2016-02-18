#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1
rm -v fuel-noop-fixtures/reports/*.json
rm -v fuel-noop-fixtures/reports/*.xml
rm -v fuel-noop-fixtures/hiera/globals/*.yaml
