#!/bin/bash -ex
# aStor2 -- storage area network configurable via Web-interface
# Copyright (C) 2009-2012 ETegro Technologies, PLC
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

[ -n "$CONFIG" ] || CONFIG=./config

. $CONFIG
. lib/functions.sh

WORK_DIR=`echo $0 | sed "s/\/perform.sh$//"`
pushd "$WORK_DIR"; WORK_DIR=`pwd`; popd
export WORK_DIR
export LC_ALL=C

test_start="`date '+%F_%R:%S'`"
for test_dir in tests/$1/*; do
	pushdq $test_dir

	test_name="`echo $test_dir | awk -F/ '{print $NF}'`"
	result_dir="$WORK_DIR/results/$test_start"
	mkdir -p $result_dir

	message "Running $test_name test"
	if RESULT_DIR="$result_dir/$test_name" ./init.sh 4>$result_dir/comment; then
		message "Succeeded"
		[ -s $result_dir/comment ] || rm -f $result_dir/comment
	else
		message "Failed"
		echo "$test_name" > $result_dir/failed
		exit 1
	fi

	popdq
done
