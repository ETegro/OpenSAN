package SAN::WEB;

use strict;
use warnings;
use utf8;

# Markup parser. This module supports most popular formats
use Text::Markup;

# Git API
use Git::Repository;

use File::Copy;

sub new() {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub load_template($) {
    my ($class, $temp_file) = @_;
    my $load;
    open(my $temp, "<$temp_file") or die "Cannot open file $temp_file: $!\n";
    while(<$temp>) {
        $load .= $_;
    }
    my $template = $load;
    return $template;
}

sub process_files() {
    my ($class, $path, $git_dir, $out_dir, $template_file) = @_;
    my $tmplt;

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
            SAN::WEB->process_files($_, $git_dir, $out_dir, $template_file);
        } else {
            if ($_ =~ /.+\/(.+)\.wiki$/) {
                my $file = $_;
                my $new_file = $1;
                #$new_file =~ s/.+\/(w+)\.wiki/$1/g;

                # Load template
                if (defined($template_file)) {
                    $tmplt = SAN::WEB->load_template($template_file);
                }

                # Parsing markup files
                #
                # SUPPORTED FORMATS:
	            # asciidoc, html, markdown,
                # mediawiki, multimarkdown, pod, rest,
                # textile, trac
                # We use mediawiki format
                my $parser = Text::Markup->new(
                            default_format => 'mediawiki',
                            default_encoding => 'UTF-8',
                            );
                my $parse_out = $parser->parse(file => $file);
                $parse_out =~ s/\{{3}/<pre>/g; # I don't know really needs it or not
                $parse_out =~ s/}}}/<\/pre>/g; #
                $parse_out =~ s/!(.+)\s(.+)\s\((.+)\)!/<img src="$1" $2 alt="$3" \/>/g;
                # print "DEBUG 90: $1\n" if defined($1);
                $parse_out =~ s/<html>/$tmplt<\/body><\/html>/g; # Paste HTML template in files head
                $parse_out =~ s/<title>(.+)<\/title>/<title>$1 :: $new_file<\/title>/g;

                $new_file = "$out_dir" . "$new_file" . ".html";
                open(NEW, ">$new_file") or die "$!\n";
                print NEW $parse_out;
            } 
           # Images
            elsif ($_ =~ /.+\/(.+\.png$)/) {
                my $file = $_;
                my $new_file = $1;
                $new_file = "$out_dir" . "img/" . "$new_file";
                copy("$file", "$new_file") or die "Copy failed: $!\n";
            }
            # CSS
            elsif ($_ =~ /.+\/(.+\.css)/) {
            	my $file = $_;
            	my $new_file = $1;
            	$new_file = "$out_dir" . "css/" . "$new_file";
            	copy("$file", "$new_file") or die "Copy failed: $!\n";
            }
        }
    }
}

# Check site updates in github.
sub check_git() {
    my ($class, $git_dir) = @_;
    my $r = Git::Repository->new(git_dir => "$git_dir") or die "$!\n";
    my $output = $r->run("pull") or die "$!\n";
    return $output;
}

1;
