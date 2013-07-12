package SAN::Config;

use Config::Tiny;

sub new() {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

sub config() {
	my ($class, $config_file) = @_;
	die "Config file not defined\n" if (!(defined($config_file)));

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
