#!/bin/bash -ex
# aStor2 -- storage area network configurable via Web-interface
# Copyright (C) 2009-2012 ETegro Technologies, PLC
#                         Sergey Matveev <sergey.matveev@etegro.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

SHA256=sha256sum
GPG=gpg

PGP_SIGN_KEYID=90EC3862
SOURCE_DIR="$1"
TARGET_DIR="$2"

usage()
{
	cat <<__EOF__
Usage: $0 SOURCE_DIR_PATH TARGET_DIR_PATH

Where:
	SOURCE_DIR_PATH -- is an ABSOLUTE path to aStor2
	                   build output directory
	TARGET_DIR_PATH -- is an ABSOLUTE path to directory
	                   for syncing with website
__EOF__
	exit 1
}

[ -n "$SOURCE_DIR" ] || usage
[ -n "$TARGET_DIR" ] || usage

echo "$SOURCE_DIR" | grep -q "^/" || usage
echo "$TARGET_DIR" | grep -q "^/" || usage

mkdir -p $TARGET_DIR
pushd $SOURCE_DIR

for build in *; do
	[ -d $TARGET_DIR/nightly/$build -o -d $TARGET_DIR/tags/$build ] && continue || true
	cp -av $build $TARGET_DIR/
	pushd $TARGET_DIR/$build
	rm -fr packages/ md5sums *vmlinuz *rootfs*
	for image in *; do
		! echo $image | grep -q "openwrt-x86" ||
			mv "$image" "`echo $image | sed 's/openwrt-x86-//'`"
	done
	$SHA256 * > checksums.sha256
	$GPG --default-key=$PGP_SIGN_KEYID \
	     --sign \
	     --armor \
	     --comment="See http://www.opensan.org/trac/wiki/Publickey" \
	     --output=- checksums.sha256 > checksums.sha256.sign
	popd
done

# Do not mix tagged releases and nightly builds
mkdir -p $TARGET_DIR/nightly
find $TARGET_DIR \
	-maxdepth 1 \
	-type d \
	-name "[0-9]*-*" \
	-exec mv "{}" $TARGET_DIR/nightly \;

mkdir -p $TARGET_DIR/tags
find $TARGET_DIR/nightly \
	-type d \
	-name \*-V\*-\* \
	-exec mv "{}" $TARGET_DIR/tags \; || true

popd
