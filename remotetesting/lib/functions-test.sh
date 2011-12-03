#!/bin/sh
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

. $WORK_DIR/lib/functions.sh

failed()
{
	if [ -n "$@" ]; then
		echo "$@" >&4 || echo "$@" >&2
	fi
	exit 1
}

_exit_handler()
{
	local rc=$?
	trap - EXIT
	type exit_handler >/dev/null 2>&1 && exit_handler || true
	exit $rc
}
trap _exit_handler HUP PIPE INT QUIT TERM EXIT
