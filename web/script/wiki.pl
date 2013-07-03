#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: wiki.pl
#
#        USAGE: ./wiki.pl  
#
#  DESCRIPTION: Script update site from github
#       AUTHOR: Denis Zheleztsov (Difrex), denis.zheleztsov@etegro.com
#      LICENSE: GNU GPL v3
# ORGANIZATION: ETegro Technologies
#      VERSION: 0.1
#      CREATED: 01.07.2013 15:45:20
#     REVISION: 004
#===============================================================================
use SAN::OpenSAN;
my $opensan = new SAN::OpenSAN;

# Path to configuration file
my $config_file;
if (-e './config') {
    $config_file = './config';
}
elsif (-e '/var/www/config') {
    $config_file = '/var/www/config';
}
elsif (-e './config' and -e '/var/www/config') {
    $config_file = './config';
}
else {
    print "Config file not found!" and die;
}

# Load configuration
my ($dir, $git_dir, $out_dir, $template_file) = $opensan->load_config($config_file);

# Load HTML template
my $template = $opensan->load_template($template_file);
my $tmplt;

# Check site updates on github.
my $git_stat = $opensan->check_git();

# Run main proccess
$opensan->process_files($dir) if $git_stat ne 'Already up-to-date.';