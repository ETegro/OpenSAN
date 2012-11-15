#!/bin/sh

for frame in frame*.txt; do
	perl -ne 'print join " ", ("", map { ord } split //)' < $frame > ${frame}.converted
done
