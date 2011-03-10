#!/bin/bash -ex

WORK_DIR=`echo $0 | sed "s/\/build.sh$//"`
pushd $WORK_DIR; WORK_DIR=`pwd`; popd
TARGET_DIR="$WORK_DIR"/openwrt/trunk
RESULT_DIR="$WORK_DIR"/output
DL_DIR="$TARGET_DIR"/dl

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

create_dl_directory()
{
	[ -L "$DL_DIR" ] && [ `readlink "$DL_DIR"` = "$DL_PATH" ] && return 0
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
	ID=`date "+%Y-%m-%dT%H:%M"`
	mkdir -p "$OUTPUT_DIR"/$ID
}

check_openwrt_existence
update_feeds_configuration
update_openwrt_config
create_dl_directory
create_output_directory
