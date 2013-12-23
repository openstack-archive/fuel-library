#!/bin/sh
LOGPARSE="logparse.rb"
PAGER="yes"

parse_file() {
  echo "=========================================================="
  echo "${1}"
  ruby "${LOGPARSE}" "${1}"
  if [ "${PAGER}" = "yes" ]; then
    read key
  fi
}

process_directory() {
  logs="`find "${1}" -name 'puppet-agent.log' -o -name 'puppet-apply.log'`"
  for log in ${logs}; do
    parse_file "${log}"
  done
}

open_snapshot() {
  if [ ! -f "${1}" ]; then
    echo "File ${1} not found!"
    exit 1
  fi
  tempdir="`mktemp -d`"

  tar -xf "${1}" -C "${tempdir}" --wildcards '*/puppet*.log'

  if [ $? -gt 0 ]; then
    echo "Untar failed or puppet logs not found!"
    exit 1
  fi

  if [ ! -d "${tempdir}" ]; then
    echo "Tempdir not found!"
    exit 1
  fi

  process_directory "${tempdir}"

  rm -rf "${tempdir}"
}

if [ -d "${1}" ]; then
  process_directory "${1}"
  exit 0
fi

case "${1}" in
  *.tar.gz)
    open_snapshot "${1}";;
  *.tgz)
    open_snapshot "${1}";;
  *.log)
    parse_file "${1}";;
  *)
    echo "File doesn't look like Fuel snapshot archive!"; exit 1 ;;
esac
