#!/bin/bash -x

. ./config
. lib/common.sh

WORK_DIR=`echo $0 | sed "s/\/perform.sh$//"`
pushd "$WORK_DIR"; WORK_DIR=`pwd`; popd

test_start="`date '+%F_%R'`"
for test_dir in tests/*; do
	pushdq $test_dir
	test_name="`echo $test_dir | awk -F/ '{print $NF}'`"
	RESULT_DIR="$WORK_DIR/results/$test_start/$test_name" . ./init.sh
	popdq
done
