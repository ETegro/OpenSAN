#!/bin/sh

WHAT=$1
CONTENTS=$2

echo >> Releases.wiki
echo "= $1 =" >> Releases.wiki
cat $CONTENTS >> Releases.wiki
