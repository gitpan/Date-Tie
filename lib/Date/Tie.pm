#/bin/perl
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

# fetch or set weekday/week will create weekday/week
# same for yearday/year
# how to copy to another var? 
# - will have to create another tied hash, then transfer the epoch to it.
# do I need 'monthday' ? 
# how to prevent leaks?
# can the data be stored inside the hash?

package Date::Tie;
use strict;
use Tie::Hash;
use Exporter;
use Time::Local qw( timegm );
use vars    qw( @ISA @EXPORT %Date %Max %Min %Mult $Infinity $VERSION );
@EXPORT =   qw( new iso );
@ISA =      qw( Tie::StdHash Exporter ); 
$VERSION =  '0.03';
$Infinity = 999_999_999_999;
%Date = ( );
%Mult = ( 	day => 24 * 60 * 60, hour => 60 * 60, minute => 60, second => 1 );

%Max  = ( 	year =>     $Infinity,  	yearday =>  365, 
			month =>    12,          	monthday => 28,
			day =>      28,         	week =>     52, 
			weekday =>  7,          	hour =>     23, 
			minute =>   59,          	second =>   59, 	epoch =>    $Infinity   );

%Min  = ( 	year =>     -$Infinity, 	yearday =>  1,   
			month =>    1,          	monthday => 1,
			day =>      1,          	week =>     1,  
			weekday =>  1,           	hour =>     0, 
			minute =>   0,          	second =>   0, 		epoch =>    -$Infinity  );

sub STORE { 
	my ($self, $key, $value) = @_; 
	my ($delta, $epoch);
	# print "STORE: ", 0+$self," $key, $value\n";
	if ($key eq 'epoch') {
		# print "  STORE: epoch: ", 0+$self," remove other keys\n";
		# remove all other keys (now invalid)
		$Date{ 0 + $self } = { epoch => $value };	
		return;
	}
	if ($key eq 'month') {
		# print "  STORE: month: ", 0+$self," remove epoch\n";
		# remove epoch key (now invalid)
		delete $Date{ 0 + $self }{epoch}; 	
		if (($value >= $Min{$key}) and ($value <= $Max{$key})) {
			$Date{ 0 + $self }{$key} = $value;
			return;
		}
		# print "  STORE: month overflow: $value\n";
		$value -= 1;
		$Date{ 0 + $self }{year} += int( $value / 12);
		$Date{ 0 + $self }{month} = 1 + $value % 12;
		return;
	}
	if ($key eq 'year') {
		# print "  STORE: year: ", 0+$self," remove epoch\n";
		# remove epoch key (now invalid)
		delete $Date{ 0 + $self }{epoch}; 	
		$Date{ 0 + $self }{year} = $value;
		return;
	}
	# all other keys
	if ( exists $Date{ 0 + $self }{$key} ) {
		$delta = $value - $Date{ 0 + $self }{$key};
	}
	else {
		$delta = $value;
	}
	if (($value >= $Min{$key}) and ($value <= $Max{$key})) {
		$Date{ 0 + $self }{epoch} += $delta * $Mult{$key} if exists $Date{ 0 + $self }{epoch};
		$Date{ 0 + $self }{$key}  =  $value;
		return;
	}
	# handle overflow
	# print "  STORE: $key overflow: $value\n";
	# init epoch key
	if ( exists $Date{ 0 + $self }{epoch} ) {
		$epoch = $Date{ 0 + $self }{epoch};
	}
	else {
		$epoch = FETCH($self, 'epoch');
	}
	# print "  STORE: ", 0+$self," remove all except epoch, $epoch [ $value * $Mult{$key} ] \n";
	$epoch += $delta * $Mult{$key};
	# remove all other keys (now invalid)
	$Date{ 0 + $self } = { epoch => $epoch };	
	return;
}

sub FETCH { 
	my ($self, $key) = @_; 
	# my $a = 0 + $self;
	# printf (" %0X ", $a);
	# print "FETCH: ", 0+$self," $key\n";
	if (exists($Date{ 0 + $self }{$key}) ) {
		$_ = $Date{ 0 + $self }{$key};
		$_ = '0' . (0 + $_) if ($_ >= 0) && ($_ < 10);
		return $_;
	}
	# create key if possible
	if (( $key eq 'epoch') or not exists $Date{ 0 + $self }{epoch} ) {
		# print "  FETCH: create epoch\n";
		my ($year, $month, $day, $hour, $minute, $second);
		$day =   exists $Date{ 0 + $self }{day} ?
			$Date{ 0 + $self }{day}   > 0 ? $Date{ 0 + $self }{day} : 1 : 1;
		$month =  exists $Date{ 0 + $self }{month} ?
			$Date{ 0 + $self }{month} > 0 ? $Date{ 0 + $self }{month} - 1 : 0 : 0;
		$year =   exists $Date{ 0 + $self }{year} ?
			$Date{ 0 + $self }{year} >= 1900 ? $Date{ 0 + $self }{year} - 1900 : 0 : 0;
		$hour =   exists $Date{ 0 + $self }{hour} ?
			$Date{ 0 + $self }{hour} : 0;
		$minute = exists $Date{ 0 + $self }{minute} ?
			$Date{ 0 + $self }{minute} : 0;
		$second = exists $Date{ 0 + $self }{second} ?
			$Date{ 0 + $self }{second} : 0;
		# print " ($year, $month, $day) \n";
	    $Date{ 0 + $self }{epoch} = timegm( $second, $minute, $hour, $day, $month, $year );
		return $Date{ 0 + $self }{epoch} if $key eq 'epoch';
	}
	# print "  FETCH: create $key and others\n";
	(	$Date{ 0 + $self }{second},	$Date{ 0 + $self }{minute},	$Date{ 0 + $self }{hour},
		$Date{ 0 + $self }{day},	$Date{ 0 + $self }{month},	$Date{ 0 + $self }{year},
		$Date{ 0 + $self }{isdst} ) = gmtime($Date{ 0 + $self }{epoch});
	$Date{ 0 + $self }{year} += 1900;
	$Date{ 0 + $self }{month}++;

	$_ = $Date{ 0 + $self }{$key};
	$_ = '0' . $_ if ($_ >= 0) && ($_ < 10);
	return $_;
}

sub new {
	my $class = shift;
	my $self = bless {}, $class;
	my ($tmp1, $tmp2);
    tie %$self, 'Date::Tie';
	while ($#_ > -1) {
		($tmp1, $tmp2) = (shift, shift);
		$self->{$tmp1} = $tmp2;
	}
	return $self;
}

# This is for debugging only !
sub iso { my $self = shift; return $self->{year} . '-' . $self->{month} . '-' . $self->{day}; }

1;

__END__

=head1 NAME
    Date::Tie - a perlish interface to dates

=head1 SYNOPSIS
	use Date::Tie;

    tie %date, 'Date::Tie';
	%date = { year => 2001, month => 11, day => '09' };
	$date{year}++;
	$date{month} += 12;    # 2003-11-09

	# you can also do this
	$date = Date::Tie->new( year => 2001, month => 11, day => '09' );
	$date->{year}++;
	$date->{month} += 12;  # 2003-11-09

=head1 DESCRIPTION

Date::Tie is an attempt to simplify date operations syntax.

Date::Tie manages a hash containing the keys: 
epoch, year, month, day, hour, minute, and second.
Whenever a new value is stored in a key, it may overflow to 
the other keys following the common (ISO) date rules. 

For example: 
	 print $a{hour}, ":", $a{minute};     #  00 59
	 $a{minute}++;
	 print $a{hour}, ":", $a{minute};     #  01 00

=head1 HISTORY
        
	0.03 STORE rewritten
		examples work

	0.02 Make it a real module

	0.01 I started this when dLux asked:
		> What about this kind of syntax:
		> my $mydate = new XXXX::Date "2001-11-07";
		> # somewhere later in the code
		> my $duedate = $mydate + 14 * XXX::Date::DAY;
		> my $duedate = $mydate + 14 * DAY;
		> my $duedate = $mydate->add(12, DAYS);
		> my $duedate = $mydate->add(day => 12);
		> my $duedate = $mydate + "12 days";
		> my $duedate = $mydate + "12 days and 4 hours and 3 seconds"; # :-)

=head1 AUTHOR
    Flávio Soibelmann Glock (fglock@pucrs.br)

