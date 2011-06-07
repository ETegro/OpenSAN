#!/bin/sh

iqns_stop_all
run_clearing
run_lua single_lvm
iqns_start_all

jobfile=`mktemp`
cat jobfile.fio > $jobfile
dev=`devs_get`
echo "filename=$dev" >> $jobfile
$FIO $jobfile | log_save fio_result
rm -f $jobfile

iqns_stop_all
