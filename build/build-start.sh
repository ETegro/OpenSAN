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

export LC_ALL=C

[ -n "$1" ] && BRANCH="$1" || BRANCH="master"

WORK_DIR=`echo $0 | sed "s/\/build-start.sh$//"`
pushd "$WORK_DIR"; WORK_DIR=`pwd`; popd

BUILD_LOG=`mktemp`
time_start=`date`

. "$WORK_DIR"/build.conf

update_repository()
{
	pushd "$WORK_DIR"
	$GIT checkout HEAD .
	$GIT fetch -p
	if `$GIT branch | grep -q "^..$BRANCH"`; then
		$GIT checkout $BRANCH
	else
		$GIT checkout -b $BRANCH origin/$BRANCH
	fi
	$GIT merge origin/$BRANCH
	popd
}

send_email()
{
	time_finish=`date`
	mailx -s "[`whoami`] failed astor2 build" $MAILTO <<__EOF__
Started: $time_start
Finished: $time_finish
Branch: $BRANCH

-----BEGIN LOG-----
`cat $BUILD_LOG`
-----END LOG-----

-- 
astor2-build-start.sh
__EOF__
}

call_build()
{
	"$WORK_DIR"/build.sh $BRANCH > $BUILD_LOG 2>&1 || send_email
}

cleanup()
{
	rm -f $BUILD_LOG
}

update_repository
call_build
cleanup

cd $WORK_DIR
for tag in `git tag | grep "^V"`; do
	if ls "$WORK_DIR"/output/ | grep -q "[-]${tag}.\?$"; then
		true
	else
		$GIT checkout HEAD .
		$GIT checkout $tag

		BRANCH="$tag"
		BUILD_LOG=`mktemp`
		time_start=`date`

		call_build
		cleanup
	fi
done
