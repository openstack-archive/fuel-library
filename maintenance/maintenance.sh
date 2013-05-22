#!/bin/bash
DIR="$(cd "$(dirname "$0")" && pwd)"
. "$DIR/functions.sh"
. "$DIR/settings.conf"

function usage {
  cat << EOF
Repository Maintenance Tool:
This tool consists of two methods:
 * import - Syncing repositories from OSCI
 * publish - Publishing internal repository to download.mirantis.com

import:
  -r RELEASETAG Fuel version being created
  -k KOJITAG OSCI tag that we should fetch
  -o OUTPUTDIR destination path for new repo
publish:
  -r RELEASETAG

Examples:
$0 import -r 2.2 -k fuel-2.2 -o ./epel-fuel-folsom-2.2 <- all OpenStack packages and deps
$0 import -r 2.2 -k fuel-folsom -o ./epel-fuel-folsom-2.2 <- just OpenStack packages
$0 import -r 2.2 -k epel-fuel-folsom -o ./epel-fuel-folsom-2.2 <- just deps

$0 publish -r epel-fuel-folsom-2.2
EOF
}
if [ -z $3 ]; then
  usage
  exit 1
fi
case $1 in
  import)	method="import"
  		;;
  publish)	method="publish"
		;;
  *)		echo "Unknown command $1"
		usage
                cleanup
		exit 1
esac
shift
outdir=$PWD
while [ -n "$2" ]; do
  case $1 in
    -r)	release=$2
        shift 2
        ;;
    -k) kojitag=$2
        shift 2
        ;;
    -o) outdir=$2
        shift 2
        ;;
    *)	echo "Unknown option $1"
        usage
        cleanup
        exit 1
        ;;
  esac
done
if [[ "$method" == "import" ]];then
  sync_repo_osci "$release" "$kojitag" "$outdir"
fi
if [[ "$method" == "publish" ]];then
  copy_to_public_mirror "$release"
fi
cleanup
