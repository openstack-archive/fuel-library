#!/bin/bash
#
# sysfs         Apply sysfs values from the config files
#
# Based on Debian 'sysfsutils' init script
#
# chkconfig: 345 15 85
# description: Sets sysfs values from the config file to the system on boot
### BEGIN INIT INFO
# Short-Description: Apply sysfs values from the config files
# Description: Apply sysfs values from the config files
### END INIT INFO

. '/etc/init.d/functions'

if [ -f '/etc/sysconfig/sysfs' ]; then
  . '/etc/sysconfig/sysfs'
fi

if [ -z "${CONFIG_FILE}" ]; then
  CONFIG_FILE='/etc/sysfs.conf'
fi

if [ -z "${CONFIG_DIR}" ]; then
  CONFIG_DIR='/etc/sysfs.d'
fi

load_conffile() {
  FILE="$1"
  echo "Load sysfs file: ${FILE}"
  sed  's/#.*$//; /^[[:space:]]*$/d;
  s/^[[:space:]]*\([^=[:space:]]*\)[[:space:]]*\([^=[:space:]]*\)[[:space:]]*=[[:space:]]*\(.*\)/\1 \2 \3/' \
  "${FILE}" | {
    while read f1 f2 f3; do
      if [ "$f1" = "mode" -a -n "$f2" -a -n "$f3" ]; then
        if [ -f "/sys/$f2" ] || [ -d "/sys/$f2" ]; then
          chmod "$f3" "/sys/$f2"
        else
          failure "unknown attribute $f2"
        fi
      elif [ "$f1" = "owner" -a -n "$f2" -a -n "$f3" ]; then
        if [ -f "/sys/$f2" ]; then
          chown "$f3" "/sys/$f2"
        else
          failure "unknown attribute $f2"
        fi
      elif [ "$f1" -a -n "$f2" -a -z "$f3" ]; then
        if [ -f "/sys/$f1" ]; then
          # Some fields need a terminating newline, others
          # need the terminating newline to be absent :-(
          echo -n "$f2" > "/sys/$f1" 2>/dev/null ||
          echo "$f2" > "/sys/$f1"
        else
          echo "unknown attribute $f1"
        fi
      else
        failure "syntax error: '$f1' '$f2' '$f3'"
        exit 1
      fi
    done
  }
}

######################################################################

case "$1" in
  start|restart|reload)
    echo "Settings sysfs values..."
    for file in ${CONFIG_FILE} ${CONFIG_DIR}/*.conf; do
      [ -r "${file}" ] || continue
      load_conffile "${file}"
    done
    ;;
  stop)
    exit 0
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|reload}"
    exit 2
esac
