package SAN::WEB;

use strict;
use warnings;
use utf8;

# Markup parser. Support most popular formats
use Text::Markup;
# Git API
use Git::Repository;

use File::Copy;
use Cwd 'abs_path';

sub new() {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub load_config($) {
	# Load configuration. Put 'config' file into dir contains wiki.pl script.
	# I know it's shitcode but Im to lazy into XML, JSON, YAML, or somethin else :)
	# TODO: Rewrite this function
	my $config_file = shift;
	open(CONF, "<$config_file") or die "Cannot open file: $!\n";
	my ($dir, $git_dir, $out_dir, $template_file);
    # my %config_hash = (); # Uncomment this if you are know what to do with this hash
	while(<CONF>) {
	    my $config = $_;
	    if ($config =~ /(^\w+)\s+=\s+(.+)$/) {
	        my $key = $1;
	        my $value = $2;
            # $config_hash{$key} = $value; # I donn't know needs it realy or not :) Just comment this line at this time
	        if ($key eq 'WorkDirectory') {
	            $dir = $value;
	        }
	        elsif ($key eq 'GitDirectory') {
	            $git_dir = $value;
	        }
	        elsif ($key eq 'OutputDirectory') {
	            $out_dir = $value;
	        }
	        # Require filename only! 
	        # Script tried to find it on WorkDirectory or in the script location.
	        elsif ($key eq 'TemplateFile') {
	                $template_file = $value;
	        }
	        else {
	            die "Cannot load configuration. Check syntax. Error: $!\n";
	        }
	    }
	}
	close(CONF);
	return $dir, $git_dir, $out_dir, $template_file;#, %config_hash;
}

sub load_template($) {
    my $temp_file = shift;
    my $load;
    open(my $temp, "<$temp_file") or die "Cannot open file $temp_file: $!\n";
    while(<$temp>) {
        $load .= $_;
    }
    my $template = $load;
    return $template;
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
            SAN::WEB->process_files($_);
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
                $parse_out =~ s/\{{3}/<pre>/g;
                $parse_out =~ s/}}}/<\/pre>/g;
                $parse_out =~ s/<html>/$tmplt<\/body><\/html>/g;

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
    my $r = Git::Repository->new(git_dir => "$git_dir") or die "$!\n";
    my $output = $r->run("pull") or die "$!\n";
    return $output;
}

1;