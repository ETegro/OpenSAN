#!/bin/sh

ASTOR2_BASEDIR=$HOME/work/astor2

mkdir -p astor2
for lib in caching common einarc lvm scst; do
	ln -s $ASTOR2_BASEDIR/feeds/astor2/astor2-lua-$lib/files/astor2/$lib.lua astor2/
done
