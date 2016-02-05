#!/bin/sh
DIR=`dirname $0`
cd "${DIR}" || exit 1
rm -v fuel-noop-fixtures/reports/*.{json,xml}
