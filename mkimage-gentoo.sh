#!/usr/bin/env bash
# gentoo verified docker deployment
# (c) 2014 Daniel Golle
#
# requirements: wget, GnuPG, OpenSSL, docker.io ;)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

buildsdirurl() {
	local mirror="$1"
	local arch="$2"
	echo "${mirror}/releases/${arch}/autobuilds"
}

snapshotdirurl() {
	local mirror="$1"
	local arch="$2"
	local flavor="$3"
	local buildsdir="$( buildsdirurl "$mirror" "$arch" )"
	echo "$buildsdir/current-stage3-${arch}${flavor:+"-"}${flavor}"
}

getversion() {
	local mirror="$1"
	local arch="$2"
	local flavor="$3"
	local buildsdir="$( buildsdirurl "$mirror" "$arch" )"
	local url="${buildsdir}/latest-stage3-${arch}${flavor:+"-"}${flavor}.txt"
	wget -q -O/dev/stdout "$url" | grep -v "#" | sed 's/\/.*//'
}

getstage3() {
	local mirror="$1"
	local arch="$2"
	local snapshotver="$3"
	local target="$4"
	local flavor="$5"

	local snapshotdirurl="$( snapshotdirurl "$mirror" "$arch" "$flavor" )"
	local stage3name="stage3-${arch}${flavor:+"-"}${flavor}-${snapshotver}.tar.bz2"
	local digestfile="${target}/${stage3name}.DIGESTS.asc"
	
	# download DIGEST file
	wget -c -q -O"$digestfile" "${snapshotdirurl}/${stage3name}.DIGESTS.asc"
	if [ ! -e "$digestfile" ]; then
		echo "can't download checksum file" 1>&2
		exit 1
	fi

	# PGP signature check of checksum file
	# start with empty pgp homedir
	local pgpsession="$( mktemp -d )"
	gpg -q --homedir "$pgpsession" --update-trustdb
	# import Gentoo Release public key
	gpg -q --homedir "$pgpsession" --keyserver pgp.mit.edu --recv-keys 2D182910
	# verify signature
	if ! gpg -q --homedir "$pgpsession" --verify "$digestfile"; then
		echo "signature verification of checksum file failed" 1>&2
		rm "$digestfile"
		rm "$pgpsession"/*
		rmdir "$pgpsession"
		exit 1
	fi
	rm "$pgpsession"/*
	rmdir "$pgpsession"

	# use only signed part of asc file
	local copy=0
	local skip=0
	local checkedfile="${target}/${stage3name}.DIGESTS.checked"
	cat "${target}/${stage3name}.DIGESTS.asc" | while read line; do
		case "$line" in
			"-----BEGIN PGP SIGNED MESSAGE"*)
				copy=1
			;;
			"-----BEGIN PGP SIGNATURE"*)
				skip=1
			;;
		esac
		[ "$copy" = "1" -a "$skip" = "0" ] && echo "$line" >> "$checkedfile"
	done || true

	# extracting SHA512 and WHIRLPOOL sums from signed part
	local sha512sum1=$( \
		grep -A 1 SHA512 "$checkedfile" | \
		grep -v "#" | grep -v "CONTENTS" | grep -v "\-\-" | sed 's/ .*//' \
	)
	local whirlpoolsum1=$( \
		grep -A 1 WHIRLPOOL "$checkedfile" | \
		grep -v "#" | grep -v "CONTENTS" | grep -v "\-\-" | sed 's/ .*//' \
	)
	rm "$checkedfile"

	# alright, now download stage3 tarball
	wget -q -c -O"${target}/${stage3name}" "${snapshotdirurl}/${stage3name}"

	local checksumsok=0

	# verifying checksums
	local sha512sum2=$( \
		openssl dgst -r -sha512 "${target}/${stage3name}" | \
		sed 's/ .*//' \
	)
	if [ "$sha512sum1" = "$sha512sum2" ]; then
		echo "sha512 ok" 1>&2
		checksumsok=$(( $checksumsok + 1 ))
	fi

	local whirlpoolsum2=$( \
		openssl dgst -r -whirlpool "${target}/${stage3name}" | \
		sed 's/ .*//' \
	)
	if [ "$whirlpoolsum1" = "$whirlpoolsum2" ]; then
		echo "whirlpool ok" 1>&2
		checksumsok=$(( $checksumsok + 1 ))
	fi

	if [ "$checksumsok" != "2" ]; then
		echo "checksums failed!" 1>&2
		rm "${target}/${stage3name}"
		exit 1
	fi

	echo "${stage3name}"
}

flavor="$1"
mirror="${2:-"http://mirror.ovh.net/gentoo-distfiles"}"

# Docker is amd64 only
arch="amd64"

target="$( mktemp -d )"

tag="gentoo-stage3${flavor:+"-"}${flavor}"

version=$( getversion "$mirror" "$arch" "$flavor" )
if [ ! "$version" ]; then
	echo "can't get latest build version of $tag" 1>&2
	exit 1;
fi

stage3=$( getstage3 "$mirror" "$arch" "$version" "$target" "$flavor" )
if [ ! "$stage3" -o ! -e "${target}/${stage3}" ]; then
	echo "no stage3" 1>&2
	exit 1;
fi

tag=$( echo $tag | sed "s/\+/-/" )
vertag="${tag}:${version}"

echo "importing ${stage3}" 1>&2
dockerimage=$( bzip2 -cd "${target}/${stage3}" | docker import - $vertag )

docker tag "$dockerimage" danthedispatcher/$vertag
docker tag "$dockerimage" danthedispatcher/${tag}:latest
