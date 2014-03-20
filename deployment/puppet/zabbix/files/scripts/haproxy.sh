#!/bin/bash
if [ -z "$1" ]; then
  echo "No argument supplied"
  exit 1
elif [ "$1" == "-f" ]; then
  OPER='discovery'
  FESQ='grep FRONTEND'
elif [ "$1" == "-b" ]; then
  OPER='discovery'
  FESQ='grep BACKEND'
elif [ "$1" == "-s" ]; then
  OPER='discovery'
  FESQ='grep -v FRONTEND\|BACKEND\|^$\|^#'
elif [ "$1" == "-v" ]; then
  OPER='value'
  IFS=$'.'
  QA=($2)
  unset IFS
  HAPX=${QA[0]}
  HASV=${QA[1]}
  ITEM=${QA[2]}
  FESQ="grep ^${HAPX},${HASV},"
fi
STATHEAD=( pxname svname qcur qmax scur smax slim stot bin bout dreq \
dresp ereq econ eresp wretr wredis status weight act bck chkfail \
chkdown lastchg downtime qlimit pid iid sid throttle lbtot tracked \
type rate rate_lim rate_max check_status check_code check_duration \
hrsp_1xx hrsp_2xx hrsp_3xx hrsp_4xx hrsp_5xx hrsp_other hanafail \
req_rate req_rate_max req_tot cli_abrt srv_abrt )

FES=`echo "show stat" | sudo socat /var/lib/haproxy/stats stdio | $FESQ`
if [ "$OPER" == "discovery" ]; then
  POSITION=1
  echo "{"
  echo " \"data\":["
  for FE in $FES
  do
      IFS=$','
      FEA=($FE)
      unset IFS
      HAPX=${FEA[0]}
      HASV=${FEA[1]}
      HASTAT=${HAPX}-${HASV}
      if [ $POSITION -gt 1 ]
      then
        echo ","
      fi
      echo -n " { \"{#HAPX}\": \"$HAPX\", \"{#HASTAT}\": \"$HASTAT\", \"{#HASV}\": \"$HASV\" }"
      POSITION=$[POSITION+1]
  done
  echo ""
  echo " ]"
  echo "}"
elif [ "$OPER" == "value" ]; then
  IFS=$','
  FEA=($FES)
  unset IFS
  cnt=0; for el in "${STATHEAD[@]}"; do
    [[ "$el" == "$ITEM" ]] && echo ${FEA[$cnt]} && break
    ((++cnt))
  done
fi