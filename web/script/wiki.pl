#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: wiki.pl
#
#        USAGE: ./wiki.pl  
#
#  DESCRIPTION: Script update site from github
#       AUTHOR: Denis Zheleztsov (Difrex), denis.zheleztsov@etegro.com
#      LICENSE: GNU GPLv3 [https://www.gnu.org/licenses/gpl.html]
# ORGANIZATION: ETegro Technologies
#      VERSION: 0.1
#      CREATED: 01.07.2013 15:45:20
#     REVISION: 005
#===============================================================================
use SAN::WEB;
use SAN::Config;

my $opensan = SAN::WEB->new();

my $config_file = "./config.ini";
# Load configuration
my $Config = SAN::Config->new();
my ($dir, $git_dir, $out_dir, $template_file) = $Config->config("$config_file");

# Load HTML template
my $tmplt;
my $template = $opensan->load_template($template_file);

# Check site updates on github.
my $git_stat = $opensan->check_git();

# Run main proccess
$opensan->process_files($dir) if $git_stat ne 'Already up-to-date.';