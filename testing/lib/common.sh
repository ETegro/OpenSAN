#!/bin/bash -x
# aStor2 -- storage area network configurable via Web-interface
# Copyright (C) 2009-2011 ETegro Technologies, PLC
#                         Sergey Matveev <stargrave@stargrave.org>
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

pushdq()
{
	pushd $@ 2>&1 >/dev/null
}

popdq()
{
	popd 2>&1 >/dev/null
}

prepare_lua()
{
	local code=$1
	cat <<__EOF__
require( "luaunit" )
common = require( "astor2.common" )
einarc = require( "astor2.einarc" )
lvm = require( "astor2.lvm" )
scst = require( "astor2.scst" )
__EOF__
	cat $code
	cat <<__EOF__
LuaUnit:run()
__EOF__
}

CMD_SSH()
{
	$SSH ${REMOTE_USER}@${REMOTE_HOST} $@
}

CMD_SCP()
{
	local src="$1"
	local dst="$2"
	$SCP "$src" ${REMOTE_USER}@${REMOTE_HOST}:"$dst"
}

run_lua()
{
	local luasrc_orig="$1".lua
	local luasrc="`mktemp`".lua
	local luasrc_name=`basename "$luasrc"`
	prepare_lua $luasrc_orig > $luasrc
	CMD_SCP "$luasrc" /tmp/"$luasrc_name"
	CMD_SCP $WORK_DIR/lib/luaunit.lua /usr/lib/lua/luaunit.lua
	CMD_SSH PATH=/bin:/sbin:/usr/bin:/usr/sbin lua /tmp/"$luasrc_name"
	CMD_SSH rm /tmp/"$luasrc_name"
	rm -f $luasrc `basename $luasrc .lua`
}

run_clearing()
{
	run_lua $WORK_DIR/lib/clearing
}

iqns_get()
{
	$ISCSIADM --mode discovery --type sendtargets --portal $REMOTE_HOST
}

iqn_login()
{
	local portal=$1
	local iqn=$2
	$ISCSIADM --mode node --targetname $iqn --portal $portal --login
}

iqn_logout()
{
	local portal=$1
	local iqn=$2
	$ISCSIADM --mode node --targetname $iqn --portal $portal --logout
	$ISCSIADM --mode node --targetname $iqn --portal $portal -o delete
}

iqns_get_local()
{
	$ISCSIADM --mode node
}

iqns_stop_all()
{
	iqns_get_local | while read iqn; do
		iqn_logout $iqn
	done
}

iqns_start_all()
{
	iqns_get | while read iqn; do
		iqn_login $iqn
		sleep 2
	done
}

devs_get()
{
	pushdq /sys/block
	for dev in sd*; do
		grep -q "blockio" $dev/device/model && echo "/dev/$dev"
	done
	popdq
}

dd_run()
{
	local dev=$1
	$DD if=/dev/zero of=$dev bs=1024k
}

log_save()
{
	local substage=$1
	mkdir -p $RESULT_DIR
	tee -a $RESULT_DIR/$substage
}
