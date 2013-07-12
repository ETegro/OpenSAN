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