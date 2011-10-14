#!/bin/sh -x
# aStor2 -- storage area network configurable via Web-interface
# Copyright (C) 2009-2011 ETegro Technologies, PLC
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
DOWNLOAD_DIR=/var/www/download

cd $DOWNLOAD_DIR

for i in `find . -maxdepth 1 -type d`; do
	echo "$i" | grep -q "^\.$" && continue || true
	cd $i
	rm -fr packages/ md5sums *vmlinuz *rootfs* checksums*
	$SHA256 * > checksums.sha256
	$GPG --default-key=$PGP_SIGN_KEYID \
	     --sign \
	     --armor \
	     --comment="See http://www.opensan.org/trac/wiki/Publickey" \
	     --output=- checksums.sha256 > checksums.sha256.asc
	cd ../
done
