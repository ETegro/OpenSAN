#!/bin/bash -ex
# aStor2 -- storage area network configurable via Web-interface
# Copyright (C) 2009-2012 ETegro Technologies, PLC
#                         Vladimir Petukhov <vladimir.petukhov@etegro.com>
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

. $WORK_DIR/config
. $WORK_DIR/lib/functions-test.sh

exit_handler()
{
	wait
	[ -f "$jobfile" ] && rm -f $jobfile
	iqns_stop_all
}

iqns_stop_all
run_clearing || failed "clearing failed"
run_lua several_lvm || failed "several_lvm failed"
iqns_start_all || failed "iqns start failed"

inc=0
jobfile=`mktemp`
for dev in `devs_get`; do
	cat jobfile.fio | sed "s:DEV:$dev:" > $jobfile
	$FIO $jobfile | log_save "fio_result$inc" || "fio $inc for $dev failed" &
	inc=$(( $inc + 1 ))
done

for i in `seq 1 $inc`; do
	wait %$i || failed "$i fio process died"
done
