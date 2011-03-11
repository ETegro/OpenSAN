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

WORK_DIR=`echo $0 | sed "s/\/build-start.sh$//"`
pushd "$WORK_DIR"; WORK_DIR=`pwd`; popd

. "$WORK_DIR"/build.conf

BUILD_LOG=`mktemp`
time_start=`date`

send_email()
{
	time_finish=`date`
	mailx -s "[`whoami`] failed astor2 build" $MAILTO <<__EOF__
Started: $time_start
Finished: $time_finish

-----BEGIN LOG-----
`cat $BUILD_LOG`
-----END LOG-----

-- 
astor2-build-start.sh
__EOF__
}

"$WORK_DIR"/build.sh > $BUILD_LOG 2>&1 || send_email
rm -f $BUILD_LOG
