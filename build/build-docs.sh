#!/bin/bash -ex
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

WORK_DIR=`echo $0 | sed "s/\/build-docs.sh$//"`
pushd $WORK_DIR; WORK_DIR=`pwd`; popd
TARGET_DIR="$WORK_DIR"/docs

. "$WORK_DIR"/build.conf

update_source_code()
{
	[ -d "$TARGET_DIR" ] || mkdir -p "$TARGET_DIR"
	if [ -d "$TARGET_DIR"/.git ]; then
		pushd "$TARGET_DIR"
		$GIT pull
		popd
	else
		$GIT clone $ASTOR2_URL "$TARGET_DIR"
	fi
}

generate_html()
{
	pushd "$TARGET_DIR"/docs
	make clean
	make html
	popd
}

update_source_code
generate_html
