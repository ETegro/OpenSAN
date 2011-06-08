#!/bin/sh

iqns_stop_all
run_clearing
run_lua single_lvm
iqns_start_all
dd_run `devs_get` 2>&1 | log_save dd_result
iqns_stop_all
