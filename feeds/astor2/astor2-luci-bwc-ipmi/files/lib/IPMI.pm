package lib::IPMI;

use strict;
use warnings;
use utf8;
use POSIX qw( setsid );

sub config_read {
    open SENSORS_FD, "< $SENSORS_CONFIG" or
        die "Unable to read sensors config: $!";
    map { /\["(.*)"\]/ and push @SENSORS, { name => $1 } }
    <SENSORS_FD>;
    close SENSORS_FD;
};

sub data_dump {
	foreach my $sensor_name (keys %DATA) {
		open SENSOR_DATA, "> ${DB_PATH}/$sensor_name" or
			die "Unable to open sensor data: $!";
		foreach my $step (reverse @{ $DATA{ $sensor_name } }) {
			print SENSOR_DATA pack $BIN_TEMPLATE, (
				$$step{zeit},
				$$step{value},
				$$step{lower_non},
				$$step{lower},
				$$step{upper_non},
				$$step{upper}
			);
		};
		close SENSOR_DATA;
	};
};

sub cycling { while(1){
	foreach my $sensor (@SENSORS) {
		my $sensor_name = $$sensor{name};
		$DATA{ $sensor_name } = [] unless defined $DATA{ $sensor_name };
		open IPMI, "$IPMITOOL sensor get \"$sensor_name\" |";
		my $value;
		my $lower;
		my $lower_non;
		my $upper;
		my $upper_non;
		while(<IPMI>){
			$value = $1 if /Sensor Reading\s*:\s*(\d+)\s*/;
			$lower = $1 if /Lower Critical\s*:\s*(\w+)\s*/;
			$lower_non = $1 if /Lower Non-Critical\s*:\s*(\w+)\s*/;
			$upper = $1 if /Upper Critical\s*:\s*(\w+)\s*/;
			$upper_non = $1 if /Upper Non-Critical\s*:\s*(\w+)\s*/;
		};
		close IPMI;
		next unless $value;
		$value = 0 if $value eq "na";
		$lower = 0 if $lower eq "na";
		$lower_non = 0 if $lower eq "na";
		$upper = 0 if $upper eq "na";
		$upper_non= 0 if $upper eq "na";
		unshift @{ $DATA{ $sensor_name } }, {
			zeit  => time,
			value => $value,
			lower => $lower,
			lower_non => $lower_non,
			upper => $upper,
			upper_non => $upper_non
		};
		$#{ $DATA{ $sensor_name } } = $STEP_COUNT - 1 if
			$#{ $DATA{ $sensor_name } } == $STEP_COUNT;
	};
	data_dump;
	sleep $STEP_TIME;
}; };

sub daemonize {
	chdir "/" or die "Unable chdir to /: $!";
	umask 0;
	open STDIN, ">/dev/null" or die "Unable read /dev/null: $!";
	open STDOUT, ">/dev/null" or die "Unable write to /dev/null: $!";
	open STDERR, ">/dev/null" or die "Unable write to /dev/null: $!";
	my $pid = fork;
	exit if $pid;
	setsid or die "Unable start a new session: $!";
};

sub data_show {
	my ($sensor_name, $only_last) = @_;
	open SENSOR_DATA, "< ${DB_PATH}/$sensor_name" or
		die "Unable to find sensor $sensor_name: $!";
	my $step;
	while( not eof SENSOR_DATA ){
		read( SENSOR_DATA, $step, 4 + 2 + 2*2 + 2*2 );
		print "[ ", join( ", ", unpack( $BIN_TEMPLATE, $step ) ), " ],\n" unless $only_last;
	};
	print join " ", unpack( $BIN_TEMPLATE, $step ), "\n" if $only_last;
	close SENSOR_DATA;
};

1;