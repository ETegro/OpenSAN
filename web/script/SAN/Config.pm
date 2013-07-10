package SAN::Config;

use Config::Tiny;

sub config($) {
	my $config_file = shift;
	
	# Read config file
	my $config = Config::Tiny->new();
	$config = Config::Tiny->read("$config_file");

	# Read directories
	my $dir = $config->{'Directory'}->{'WorkDirectory'};
	my $git_dir = $config->{'Directory'}->{'GitDirectory'};
	my $out_dir = $config->{'Directory'}->{'OutputDirectory'};

	# Read files
	my $template_file = $config->{'Files'}->{'TemplateFile'};

	return $dir, $git_dir, $out_dir, $template_file;
}

1;