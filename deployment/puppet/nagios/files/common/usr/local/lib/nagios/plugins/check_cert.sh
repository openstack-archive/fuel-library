#!/bin/sh

# Checks if a given cert on disk will expire soon

# Copyright 2009 Peter Palfrader
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

set -u
set -e

# warn if expires within 2 weeks, critical if within a day or already is expired
warn=1209600
crit=86400

if [ "$#" != 1 ]; then
	echo "Usage: $0 <certfile>" >&2
	exit 3
fi

cert="$1"

if ! [ -r "$cert" ] ; then
	echo "Cert file ($cert) does not exist or is not readable" >&2
	exit 3
fi

expires=`openssl x509 -enddate -noout < "$cert"`

if openssl x509 -checkend "$warn" -noout < "$cert" ; then
	echo "OK: $expires"
	exit 0
fi
if openssl x509 -checkend "$crit" -noout < "$cert" ; then
	echo "WARN: $expires"
	exit 1
fi
echo "CRITICAL: $expires"
exit 2
