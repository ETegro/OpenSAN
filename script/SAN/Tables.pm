package SAN::Tables;

sub new() {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;	
}

sub parse_tables() {
	my ($class, $input) = shift;
	$input =~ s/^\{|\s?(.+)?\s?(.+)/<table\s$1\s$2>/g;
	$input =~ s/^|-/<tr><td>/g;
	
}

1;