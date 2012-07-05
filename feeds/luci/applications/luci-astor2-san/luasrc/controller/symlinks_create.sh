#!/bin/sh

ASTOR2_BASEDIR=$HOME/work/astor2

mkdir -p astor2
for lib in caching common einarc lvm scst; do
	ln -f -s $ASTOR2_BASEDIR/feeds/astor2/astor2-lua-$lib/files/astor2/$lib.lua astor2/
done

for t in tests/*_; do
	ln -f -s `basename $t` tests/`basename $t _`
done

for l in uci sha2; do
	echo "return {}" > $l.lua
done
