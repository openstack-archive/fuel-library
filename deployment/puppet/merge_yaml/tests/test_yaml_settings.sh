#!/bin/sh

DIR=`dirname $0`
cd "${DIR}" || exit 1

puppet apply -vd --evaltrace --trace --modulepath=../.. test_yaml_settings.pp
