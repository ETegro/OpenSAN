#!/usr/bin/perl

# This web server needs ONLY for a test!
# Perfomance is shit but it's working :)

use strict;
use warnings;
use utf8;

use HTTP::Server::Brick;
    
my $server = HTTP::Server::Brick->new( port => 5000 );
    
$server->mount( '/' => {
	path => "/home/denis/soft/job/",
    });
     
$server->mount( '/soft' => {
        path => "/home/denis/soft/",
        });
# start accepting requests (won't return unless/until process
# receives a HUP signal)
$server->start;
