#!/bin/bash

# Check if the running kernel has the same version string as the on-disk
# kernel image.

# Copyright 2008,2009,2011 Peter Palfrader
# Copyright 2009 Stephen Gran
# Copyright 2010 Uli Martens
# Copyright 2011 Alexander Reichle-Schmehl
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

OK=0;
WARNING=1;
CRITICAL=2;
UNKNOWN=3;

get_offset() {
	local file needle

	file="$1"
	needle="$2"
	perl -e '
		undef $/;
		$i = index(<>, "'"$needle"'");
		if ($i < 0) {
			exit 1;
		};
		print $i,"\n"' < "$file"
}

get_avail() {
	# This is wrong, but leaves room for when we have to care for machines running
	# myfirstunix-image-0.1-dsa-arm
	local prefix="$1"; shift

	local kervers=$(uname -r)

	local metavers=''

	# DSA uses kernel versions of the form 2.6.29.3-dsa-dl380-oldxeon, where
	# Debian uses versions of the form 2.6.29-2-amd64
	if [ "${kervers//dsa}" != "$kervers" ]; then
		metavers=$(echo $kervers | sed -r -e 's/^2\.(4|6)\.[0-9]+([\.0-9]+?)-(.*)/2.\1-\3/')
	else
		metavers=$(echo $kervers | sed -r -e 's/^2\.(4|6)\.[0-9]+-[A-Za-z0-9\.]+-(.*)/2.\1-\2/')
	fi

	# Attempt to track back to a metapackage failed.  bail
	if [ "$metavers" = "$kervers" ]; then
		return 2
	fi

	# We're just going to give up if we can't find a matching metapackage
	# I tried being strict once, and it just caused a lot of headaches.  We'll see how
	# being lax does for us

	local output=$(apt-cache policy ${prefix}-image-${metavers} 2>/dev/null)
	local metaavailvers=$(echo "$output" | grep '^  Candidate:' | awk '{print $2}')
	local metainstavers=$(echo "$output" | grep '^  Installed:' | awk '{print $2}')

	if [ -z "$metaavailvers" ] || [ "$metaavailvers" = '(none)' ]; then
		return 2
	fi
	if [ -z "$metainstavers" ] || [ "$metainstavers" = '(none)' ]; then
		return 2
	fi

	if [ "$metaavailvers" != "$metainstavers" ] ; then
		echo "${prefix}-image-${metavers} $metaavailvers available but $metainstavers installed"
		return 1
	fi

	local imagename=0
	# --no-all-versions show shows only the candidate
	for vers in $(apt-cache --no-all-versions show ${prefix}-image-${metavers} | sed -n 's/^Depends: //p' | tr ',' '\n' | tr -d ' ' | grep ${prefix}-image | awk '{print $1}' | sort -u); do
		if dpkg --compare-versions $vers gt $imagename; then
			imagename=$vers
		fi
	done

	if [ -z "$imagename" ] || [ "$imagename" = 0 ]; then
		return 2
	fi

	if [ "$imagename" != "${prefix}-image-${kervers}" ]; then
		if dpkg --compare-versions "$imagename" lt "${prefix}-image-${kervers}"; then
			return 2
		fi
		echo "$imagename" != "${prefix}-image-${kervers}"
		return 1
	fi

	local availvrs=$(apt-cache policy ${imagename} 2>/dev/null | grep '^  Candidate' | awk '{print $2}')
	local kernelversion=$(apt-cache policy ${prefix}-image-${kervers} 2>/dev/null | grep '^  Installed:' | awk '{print $2}')

	if [ "$availvrs" = "$kernelversion" ]; then
		return 0
	fi

	echo "$kernelversion != $availvrs"
	return 1
}

get_image_linux() {
	local image GZHDR1 GZHDR2 LZHDR off

	image="$1"

	GZHDR1="\x1f\x8b\x08\x00"
	GZHDR2="\x1f\x8b\x08\x08"
	LZHDR="\x00\x00\x00\x02\xff"

	off=`get_offset "$image" $GZHDR1`
	[ "$?" != "0" ] && off="-1"
	if [ "$off" -eq "-1" ]; then
		off=`get_offset "$image" $GZHDR2`
		[ "$?" != "0" ] && off="-1"
	fi
	if [ "$off" -eq "0" ]; then
		zcat < "$image"
		return
	elif [ "$off" -ne "-1" ]; then
		(dd ibs="$off" skip=1 count=0 && dd bs=512k) < "$image"  2>/dev/null | zcat 2>/dev/null
		return
	fi

	off=`get_offset "$image" $LZHDR`
	[ "$?" != "0" ] && off="-1"
	if [ "$off" -ne "-1" ]; then
		(dd ibs="$[off-1]" skip=1 count=0 && dd bs=512k) < "$image" 2>/dev/null | lzcat 2>/dev/null
		return
	fi

	echo "ERROR: Unable to extract kernel image." 2>&1
	exit 1
}

freebsd_check_running_version() {
	local imagefile="$1"; shift

	local r="$(uname -r)"
	local v="$(uname -v| sed -e 's/^#[0-9]*/&:/')"

	local q='@\(#\)FreeBSD '"$r $v"

	if zcat "$imagefile" | strings | egrep -q "$q"; then
		echo "OK"
	else
		echo "not OK"
	fi
}

searched=""
for on_disk in \
	"/boot/vmlinuz-`uname -r`"\
	"/boot/vmlinux-`uname -r`"\
	"/boot/kfreebsd-`uname -r`.gz"; do

	if [ -e "$on_disk" ]; then
		if [ ! -x "$(which strings)" ]; then
			echo "UNKNOWN: 'strings' command missing, perhaps install binutils?"
			exit $UNKNOWN
		fi
		if [ "${on_disk/vmlinu}" != "$on_disk" ]; then
			on_disk_version="`get_image_linux "$on_disk" | strings | grep 'Linux version' | head -n1`"
			if [ -x /usr/bin/lsb_release ] ; then
				vendor=$(lsb_release -i -s)
				if [ -n "$vendor" ] && [ "xDebian" != "x$vendor" ] ; then
					on_disk_version=$( echo $on_disk_version|sed -e "s/ ($vendor [[:alnum:]\.-]\+ [[:alnum:]\.]\+)//")
				fi
			fi
			[ -z "$on_disk_version" ] || break
			on_disk_version="`cat "$on_disk" | strings | grep 'Linux version' | head -n1`"
			[ -z "$on_disk_version" ] || break

			echo "UNKNOWN: Failed to get a version string from image $on_disk"
			exit $UNKNOWN
		else
			on_disk_version="$(zcat $on_disk | strings | grep Debian | head -n 1 | sed -e 's/Debian [[:alnum:]]\+ (\(.*\))/\1/')"
		fi
	fi
	searched="$searched $on_disk"
done

if ! [ -e "$on_disk" ]; then
	echo "WARNING: Did not find a kernel image (checked$searched) - I have no idea which kernel I am running"
	exit $WARNING
fi

if [ "$(uname -s)" = "Linux" ]; then
	running_version="`cat /proc/version`"
	if [ -z "$running_version" ] ; then
		echo "UNKNOWN: Failed to get a version string from running system"
		exit $UNKNOWN
	fi

	if [ "$running_version" != "$on_disk_version" ]; then
		echo "WARNING: Running kernel does not match on-disk kernel image: [$running_version != $on_disk_version]"
		exit $WARNING
	fi

	ret="$(get_avail linux)"
	if [ $? = 1 ]; then
		echo "WARNING: Kernel needs upgrade [$ret]"
		exit $WARNING
	fi
else
	image_current=$(freebsd_check_running_version $on_disk)
	running_version="`uname -s` `uname -r` `uname -v`"
	if [ "$image_current" != "OK" ]; then
		approx_time="$(date -d "@`stat -c '%Y' "$on_disk"`" +"%Y-%m-%d %H:%M:%S")"
		echo "WARNING: Currently running kernel ($running_version) does not match on disk image (~ $approx_time)"
		exit $WARNING;
	fi

	ret="$(get_avail linux)"
	if [ $? = 1 ]; then
		echo "WARNING: Kernel needs upgrade [$ret]"
		exit $WARNING
	fi
fi

echo "OK: Running kernel matches on disk image: [$running_version]"
exit $OK
