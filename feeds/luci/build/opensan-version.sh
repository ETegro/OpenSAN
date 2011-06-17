#!/bin/bash
# aStor2 -- storage area network configurable via Web-interface
# Copyright (C) 2009-2011 ETegro Technologies, PLC
#                         Sergey Matveev <stargrave@stargrave.org>
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

got_ref=0
while [ "$got_ref" != 1 ]; do
	[ -d ".git" ] && got_ref=1 || cd ../
done

commit=`git show-ref HEAD | awk '{print $1}'`
git describe --tags $commit 2>/dev/null || echo $commit
git show $commit | sed -n "s/^Date: *\(.*\)$/\1/p"
