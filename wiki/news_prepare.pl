#!/usr/bin/perl
# aStor2 -- storage area network configurable via Web-interface
# Copyright (C) 2009-2011 ETegro Technologies, PLC
#                         Sergey Matveev <sergey.matveev@etegro.com>
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

use strict;
use warnings;

my @input = <STDIN>;
my $c = 0;

my @cought_hrs = ();
my @cought_refs = ();

for( ; $c < $#input; $c++ ){
	(push @cought_hrs, $c) and print STDERR "HR at $c\n"
		if $input[ $c ] =~ /^\s*_{40,}/;
	(push @cought_refs, $c) and print STDERR "REF at $c\n"
		if $input[ $c ] =~ /^References$/;
};

my %ms = ();
$c = 1;
map { ($ms{ $1 } = $c) and $c++ if /^\s{2}(\d+)\.\s.*$/ }
	@input[ $cought_refs[-1]+26 .. $#input-4 ];
map { print STDERR "MAP $_ -> $ms{$_}\n" } sort keys %ms;

@input = (
	@input[ $cought_hrs[0]+4 .. $cought_hrs[-1]-5 ],
	@input[ $cought_refs[-1]-1 .. $cought_refs[-1]+1 ],
	@input[ $cought_refs[-1]+26 .. $#input-4 ]
);

foreach my $s (keys %ms){
	@input = grep {
		s/\[$s\]/[$ms{$s}]/g;
		s/^\s{2}$s\./  $ms{$s}./g;
		$_ } @input;
};

map { print } @input;
