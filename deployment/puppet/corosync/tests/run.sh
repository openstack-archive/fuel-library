#!/bin/bash
DIR=`dirname $0`
cd ${DIR} || exit 1

apply() {
  echo "Apply '${1}'"
  puppet apply -vd --detailed-exitcodes "${1}"
  if [ $? -eq 2 -o $? -eq 0 ]; then
    echo "Test '${1}' OK!"
  else
    echo "Test '${1}' FAIL!"
    exit 1
  fi
}

apply resource/present.pp
apply resource/absent.pp

apply order/present.pp
apply order/absent.pp

apply location/present.pp
apply location/absent.pp

apply colocation/present.pp
apply colocation/absent.pp

apply rsc_default/present.pp
apply rsc_default/absent.pp

apply property/present.pp
apply property/absent.pp

apply service/start.pp
apply service/stop.pp

apply shadow/shadow_commit.pp
