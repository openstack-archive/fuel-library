#!/bin/sh
#

if [ "$#" -ne 3 ]; then
  echo "usage: $0 <INCOMMON_ID> <CERT_DIR> <CERT_CN>"
  echo ""
  echo "example:"
  echo ""
  echo "    $0 12345 /etc/pki/tls/certs my-ssl-cert.crt"
fi

ID=$1
CERTDIR=$2
CERTCN=$3
CURL=$(which curl)
HEAD=$(which head)

URL="https://cert-manager.com/customer/InCommon/ssl?action=download&sslId=${ID}"
URL_X509="${URL}&format=x509CO"
URL_INT="${URL}&format=x509IO"

if [ -f "${CERTDIR}/meta/${CERTCN}.lock" ]; then
  # cert lock exists, return non-zero and exit
  echo "cert lock exists, exiting" >&2
  exit 1
fi

# we don't have a lock file, let's try to download the cert and see if it is
# valid, returning the RC for Puppet
$CURL -q --silent ${URL_X509} -o "${CERTDIR}/meta/${CERTCN}.crt.tmp"
$HEAD -n1 "${CERTDIR}/meta/${CERTCN}.crt.tmp" | grep 'BEGIN CERTIFICATE' >&2
exit $?
