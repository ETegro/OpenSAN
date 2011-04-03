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
TARGET_DIR="$WORK_DIR"/openwrt/trunk
OUTPUT_DIR="$WORK_DIR"/output/`date "+%Y-%m-%dT%H:%M"`-$BRANCH
DL_DIR="$TARGET_DIR"/dl
BIN_DIR="$TARGET_DIR"/bin/x86
[ -n "$JOBS" ] || JOBS=1

mmake()
{
	yes "" | $MAKE -C "$TARGET_DIR" $@
}

. "$WORK_DIR"/build.conf

checkout_openwrt()
{
	$SVN -r$OPENWRT_TRUNK_REVISION checkout $OPENWRT_TRUNK_URL "$TARGET_DIR"
}

check_openwrt_existence()
{
	[ -d "$TARGET_DIR" ] || mkdir -p "$TARGET_DIR"
	[ -d "$TARGET_DIR"/.svn ] || checkout_openwrt
	pushd "$TARGET_DIR"
	$SVN update -r$OPENWRT_TRUNK_REVISION || checkout_openwrt
	popd
}

update_feeds_configuration()
{
	local feeds_conf=feeds.conf.default

	pushd "$TARGET_DIR"
	cp /dev/null "$feeds_conf"
	echo "$FEEDS" | while read feed; do
		echo "Feed: $feed"
		feed_type=`echo "$feed" | awk '{print $1}'`
		feed_name=`echo "$feed" | awk '{print $2}'`
		feed_path=`echo "$feed" | awk '{print $3}'`
		revision=`echo "$feed" | awk '{print $4}'`
		[ "$feed_type" != "src-link" ] || feed_path="$WORK_DIR"/"$feed_path"
		echo "$feed_type $feed_name $feed_path" >> "$feeds_conf"
		./scripts/feeds update $feed_name
		if [ "$revision" = "" ]; then
			true
		else
			case $feed_type in
			"src-svn")
				pushd feeds/$feed_name
				$SVN update -r$revision
				popd
				;;
			*)
				echo "Unsupported feed type for retreiving specified version"
				exit 1
				;;
			esac
			./scripts/feeds update -i $feed_name
		fi
		./scripts/feeds install -a -p $feed_name
	done
	popd
}

update_openwrt_config()
{
	rm -f "$TARGET_DIR"/.config
	ln -s "$WORK_DIR"/.config "$TARGET_DIR"/.config
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
	mkdir -p "$DL_DIR"
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

check_openwrt_existence
update_openwrt_config
remove_dl_directory
perform_cleaning
update_feeds_configuration
update_openwrt_config
create_dl_directory
create_output_directory
perform_building
copy_bins
