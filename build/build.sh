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

[ -n "$1" ] && BRANCH="$1" || BRANCH="master"

WORK_DIR=`echo $0 | sed "s/\/build.sh$//"`
pushd "$WORK_DIR"; WORK_DIR=`pwd`; popd
TARGET_DIR="$WORK_DIR"/../openwrt
OUTPUT_DIR="$WORK_DIR"/output/`date "+%Y-%m-%dT%H:%M"`-$BRANCH
DL_DIR="$TARGET_DIR"/dl
BIN_DIR="$TARGET_DIR"/bin/x86
[ -n "$JOBS" ] || JOBS=1

mmake()
{
	yes "" | $MAKE -C "$TARGET_DIR" $@
}

. "$WORK_DIR"/build.conf

update_openwrt_config()
{
	rm -f "$TARGET_DIR"/.config
	git checkout HEAD "$TARGET_DIR"/.config
}

remove_dl_directory()
{
	[ -e "$DL_DIR" ] || return 0
	[ -L "$DL_DIR" ] && rm -f "$DL_DIR" || rm -fr "$DL_DIR"
}

create_dl_directory()
{
	[ -L "$DL_DIR" ] && [ `readlink "$DL_DIR"` = "$DL_PATH" ] && return 0 || true
	if [ -d "$DL_DIR" ]; then
		rm -fr "$DL_DIR"
	else
		rm -f "$DL_DIR"
	fi
	ln -s "$DL_PATH" "$DL_DIR"
}

create_output_directory()
{
	[ -d "$OUTPUT_DIR" ] || mkdir -p "$OUTPUT_DIR"
}

perform_cleaning()
{
	[ "$MRPROPER" = "true" ] && mmake distclean || mmake clean
}

perform_building()
{
	mmake -j$JOBS V=99 >"$OUTPUT_DIR"/output.log 2>&1
}

copy_bins()
{
	[ -d "$BIN_DIR" ] || return 0
	cp -a "$BIN_DIR"/* "$OUTPUT_DIR"/
}

update_feeds()
{
	pushd "$TARGET_DIR"
	./scripts/feeds update
	./scripts/feeds install -a
	popd
}

update_openwrt_config
remove_dl_directory
perform_cleaning
update_openwrt_config
create_dl_directory
create_output_directory
update_feeds
perform_building
copy_bins
