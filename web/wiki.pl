#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: wiki.pl
#
#        USAGE: ./wiki.pl  
#
#  DESCRIPTION: This script updates site from github
#       AUTHOR: Denis Zheleztsov (Difrex), denis.zheleztsov@etegro.com
#      LICENSE: GNU GPL v3
# ORGANIZATION: ETegro Technologies
#      VERSION: 0.1
#      CREATED: 01.07.2013 15:45:20
#     REVISION: 000
#===============================================================================

use strict;
use warnings;
use utf8;

use Text::Markup;
use Git::Repository;
use File::Copy;

# Load configuration
open(CONF, "<config") or die "Cannot open file: $!\n";
my ($dir, $git_dir, $out_dir);
while(<CONF>) {
    my $param = $_;
    if ($param =~ /(\w+)=(.+$)/) {
        my $key = $1;
        my $value = $2;
        if ($key eq 'Directory') {
            $dir = $value;
        }
        elsif ($key eq 'GitDirectory') {
            $git_dir = $value;
        }
        elsif ($key eq 'OutputDirectory') {
            $out_dir = $value;
        }
        else {
            die "Cannot load configuration. Check syntax. Error: $!\n";
        }
    }
}
close(CONF);

# my $dir = '/var/www/git/';
# my $git_dir = $dir . ".git";
# my $out_dir = '/var/www/site/';

sub recurse($) {
    my $dir = shift;
    process_files($dir);
}

sub process_files($) {
    my $path = shift;

    # Open the directory.
    opendir (DIR, $path)
        or die "Unable to open $path: $!";

    my @files = grep { !/^\.{1,2}$/ } readdir (DIR);

    # Close the directory.
    closedir (DIR);

    # At this point you will have a list of filenames
    #  without full paths ('filename' rather than
    #  '/home/count0/filename', for example)
    # You will probably have a much easier time if you make
    #  sure all of these files include the full path,
    #  so here we will use map() to tack it on.
    #  (note that this could also be chained with the grep
    #   mentioned above, during the readdir() ).
    @files = map { $path . '/' . $_ } @files;

    for (@files) {

        # If the file is a directory
        if (-d $_) {
            # Here is where we recurse.
            # This makes a new call to process_files()
            # using a new directory we just found.
            recurse($_);

        # If it isn't a directory, lets just do some
        # processing on it.
        } else {
            if ($_ =~ /.+\/(.+)\.wiki$/) {
                my $file = $_;
                my $new_file = $1;
                #$new_file =~ s/.+\/(w+)\.wiki/$1/g;

                # Parsing markup files
                my $parser = Text::Markup->new(
                            default_format => 'rest',
                            default_encoding => 'UTF-8',
                        );
                my $parse_out = $parser->parse(file => $file);
#                 $parse_out =~ s/\*\*(.+)\*\*/<i>$1<\/i>/g;
                $parse_out =~ s/\{{3}/<pre>/g;
                $parse_out =~ s/}}}/<\/pre>/g;
                $parse_out =~ s/(<html>)/$1\n<head>\n<link rel="stylesheet" href="http:\/\/st\.pimg\.net\/tucs\/style\.css" type="text\/css" \/>\n<link rel="stylesheet" href="http:\/\/yandex\.st\/highlightjs\/7\.3\/styles\/default\.min\.css">\n<script src="http:\/\/yandex.st\/highlightjs\/7\.3\/highlight\.min\.js"><\/script>\n/g;

                $new_file = "$out_dir" . "$new_file" . ".html";
                open(NEW, ">$new_file") or die "$!\n";
                print NEW $parse_out;
            }
            # Images
            elsif ($_ =~ /.+\/(.+\.png$)/) {
                my $file = $_;
                my $new_file = $1;
                $new_file = "$out_dir" . "img/" . "$new_file";
                copy("$file", "$new_file") or die "Copy fiiled: $!\n";
            }
        }
    }
}

# Check site updates on github.
sub check_git() {
    my $r = Git::Repository->new(git_dir => $git_dir) or die "$!\n";
    my $output = $r->run("pull") or die "$!\n";
    return $output;
}

my $out = check_git();

process_files("$dir") if $out ne 'Already up-to-date.';