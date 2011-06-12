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

corresponding_tag()
{
	local commit=$1
	cd .git/refs/tags
	for tag in *; do
		mtag=`cat $tag`
		if [ "$mtag" = "$commit" ]; then
			echo $tag
			return
		fi
	done
	echo ""
}

ref=`awk '{print $2}' < .git/HEAD`
if [ "$ref" = "" ]; then
	commit=`cat .git/HEAD`
	echo `corresponding_tag $commit`
else
	commit=`cat .git/$ref`
	tag=`corresponding_tag $commit`
	[ "$tag" = "" ] && echo $commit || echo $tag
fi

git show $commit | sed -n "s/^Date: *\(.*\)$/\1/p"
