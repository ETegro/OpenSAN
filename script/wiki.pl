#!/usr/bin/env perl
#===============================================================================
#
#         FILE: wiki.pl
#
#        USAGE: ./wiki.pl  
#
#  DESCRIPTION: Script updates site from github
#       AUTHOR: Denis Zheleztsov (Difrex), denis.zheleztsov@etegro.com
#      LICENSE: GNU GPLv3 [https://www.gnu.org/licenses/gpl.html]
# ORGANIZATION: ETegro Technologies
#      VERSION: 0.1.1-6alfa
#      CREATED: 01.07.2013 15:45:20
#===============================================================================
use SAN::Config;
use SAN::WEB;

# Load configuration
my $config_file = "/etc/website/config.ini";
die <<"ERR"
    Config file doesn't exists. Please write it. 
    See example.config. Save it to /etc/website/config.ini.
    You can change path to file in \$config_file variable
    in wiki.pl file
ERR
    if (!(-e $config_file));
my $Config = SAN::Config->new();
my ($dir, $git_dir, $out_dir, $template_file) = $Config->config("$config_file");

# print "TEMP: $template_file\nDIR: $dir\nGIT_DIR: $git_dir\nOUT_DIR: $out_dir\n"; # Debug

my $WEB = SAN::WEB->new();

# Check site updates on github.
my $git_stat = $WEB->check_git($git_dir);

# Load HTML template
my $template = $WEB->load_template($template_file);

# Run main proccess
$WEB->process_files($dir, $git_dir, $out_dir, $template_file)
    if $git_stat ne 'Already up-to-date.';