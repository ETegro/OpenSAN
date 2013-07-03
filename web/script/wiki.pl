#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: wiki.pl
#
#        USAGE: ./wiki.pl  
#
#  DESCRIPTION: Script updates site from github
#       AUTHOR: Denis Zheleztsov (Difrex), denis.zheleztsov@etegro.com
#      LICENSE: GNU GPL v3
# ORGANIZATION: ETegro Technologies
#      VERSION: 0.1
#      CREATED: 01.07.2013 15:45:20
#     REVISION: 001
#===============================================================================
use SAN::OpenSAN;

# Path to configuration file
my $config_file = './config';

# Load configuration
my ($dir, $git_dir, $out_dir, $template_file) = SAN::OpenSAN->load_config($config_file);
# Load HTML template
my $template = SAN::OpenSAN->load_template($template_file);

# Check site updates on github.
my $git_stat = SAN::OpenSAN->check_git();

# Run main proccess
SAN::OpenSAN->process_files($dir) if $git_stat ne 'Already up-to-date.';