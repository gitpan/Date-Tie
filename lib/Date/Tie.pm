#/bin/perl
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Date::Tie;
use strict;
use Tie::Hash;
use Exporter;
use Time::Local qw( timegm );
use vars    qw( @ISA @EXPORT %Max %Min %Mult $Infinity $VERSION );
@EXPORT =   qw( new iso );
@ISA =      qw( Tie::StdHash Exporter ); 
$VERSION =  '0.08';
$Infinity = 999_999_999_999;
%Mult = (   day => 24 * 60 * 60,       hour => 60 * 60,         minute => 60, second => 1,
            monthday => 24 * 60 * 60,  weekday => 24 * 60 * 60, yearday => 24 * 60 * 60, 
            week => 7 * 24 * 60 * 60,  tzhour => 60 * 60,       tzminute => 60 );

%Max  = (   year =>     $Infinity,     yearday =>  365,         month =>    12,  
            monthday => 28,            day =>      28,          week =>     52, 
            weekday =>  7,             hour =>     23,          minute =>   59,  
            second =>   59,            weekyear => $Infinity,   epoch =>    $Infinity );

%Min  = (   year =>     -$Infinity,    yearday =>  1,           month =>    1, 
            monthday => 1,             day =>      1,           week =>     1,  
            weekday =>  1,             hour =>     0,           minute =>   0, 
            second =>   0,             weekyear => -$Infinity,  epoch =>    -$Infinity  );

sub STORE { 
    my ($self, $key, $value) = @_; 
    my ($delta);
    $key = 'day' if $key eq 'monthday';
    $value += 0;
    # print "STORE:  $key, $value to ", $self->debug , "\n";
    if ($key eq 'tz') {
        STORE($self, 'tzminute', $value - 40 * int($value / 100));   #  60 - 100 !
        return;
    }
    if (($key eq 'tzhour') or ($key eq 'tzminute')) {
        if ($key eq 'tzhour') {
            $delta = $value * 3600 - $self->{tz100};
        }
        else {
            $delta = $value * 60   - $self->{tz100};
        }
        # print "  STORE: TZ $key $value : delta = $delta [ $self->{tz100} ]\n";
        FETCH($self, 'epoch') unless exists $self->{epoch};
        $self->{epoch} += $delta;
        $self->{tz100} += $delta;
        # print "  STORE: TZ now $self->{tz100}\n";
        %{$self} = ( epoch => $self->{epoch}, tz100 => $self->{tz100} );    
        return;
    }
    if ($key eq 'epoch') {
        # print "  STORE: epoch:  remove all other keys\n";
        $self->{epoch} = $value;
        # remove all other keys (now invalid)
        %{$self} = ( epoch => $self->{epoch}, tz100 => $self->{tz100} );    
        return;
    }
    if ($key eq 'month') {
        return if (exists $self->{month}) and ($self->{month} == $value);
        # print "  STORE: month:  remove epoch\n";
	$self->FETCH('day') unless exists $self->{day};  # save 'day' before deleting epoch!

        delete $self->{epoch};     
        delete $self->{weekday};     
        delete $self->{yearday};     
        delete $self->{week};     
        delete $self->{weekyear};     

        if (($value >= $Min{$key}) and ($value <= $Max{$key})) {
            $self->{$key} = $value;
            # return;
        }
        else {
            # print "  STORE: month overflow: $value\n";
            $value -= 1;
            $self->{year} += int( $value / 12);
            $self->{month} = 1 + $value % 12;
        }

        # $self->FETCH('day');
        if ($self->{day} >= 29) {
            my ($tmp_month) = $self->FETCH('month');
            # check for day oveflow
            # print " check \n";
            $self->STORE('day',$self->{day});
            $self->FETCH('month');
            if ($tmp_month != $self->{month}) {
                # print "  overflow! \n";
                $self->STORE('day', 0);
            }
        }

        return;
    }
    if ($key eq 'year') {
        return if (exists $self->{year}) and ($self->{year} == $value);
        # print "  STORE: year: remove epoch\n";

        delete $self->{epoch};     
        delete $self->{weekday};     
        delete $self->{yearday};     
        delete $self->{week};     
        delete $self->{weekyear};     

        $self->{year} = $value;

        $self->FETCH('day');
        if ($self->{day} >= 29) {
            my ($tmp_month) = $self->FETCH('month');
            # check for day oveflow
            # print " check ";
            $self->STORE('day',$self->{day});
            $self->FETCH('month');
            if ($tmp_month != $self->{month}) {
                # print " yr-overflow $tmp_month != ", $self->{month}," \n";
                $self->STORE('day', 0);
            }
        }

        return;
    }
    if ($key eq 'weekyear') {
        # print "  STORE: weekyear\n";
        my $week =     exists $self->{week} ?     $self->{week} :     FETCH($self, 'week');
        my $weekyear = exists $self->{weekyear} ? $self->{weekyear} : FETCH($self, 'weekyear');
        FETCH($self, 'epoch') unless exists $self->{epoch};
        $self->{epoch} += 52 * $Mult{week} * ($value - $weekyear);
        %{$self} = ( epoch => $self->{epoch}, tz100 => $self->{tz100} );    
        my $week2 =    FETCH($self, 'week');
        while ($week2 != $week) {
            STORE($self, 'week', $week2 + ($value <=> $weekyear) );
            $week2 =   FETCH($self, 'week');
            # print "  STORE: weekyear: week now is $week2\n";
        }
        # $self->{weekyear} = $value;
        return;
    }
    # all other keys

    unless ( exists $self->{$key} ) {
        # print "  STORE: create $key\n";
        FETCH($self, $key);
    }
    $delta = $value - $self->{$key};

    if (($value >= $Min{$key}) and ($value <= $Max{$key}) and 
        ($key ne 'weekday') and ($key ne 'yearday') and ($key ne 'week')) {
        $self->{epoch} += $delta * $Mult{$key} if exists $self->{epoch};
        $self->{$key}  =  $value;
        # update dependencies
        if ($key eq 'day') {
            delete $self->{weekday};     
            delete $self->{yearday};
            delete $self->{weekyear};
            delete $self->{week};     
        }
        return;
    }
    # handle overflow
    # print "  STORE: $key overflow: $value\n";
    # init epoch key
    unless ( exists $self->{epoch} ) {
        # print "  STORE: create epoch\n";
        FETCH($self, 'epoch');
        # print "  STORE: epoch is $self->{epoch} ",join(':',gmtime($self->{epoch})),"\n";
    }
    # print "  STORE: remove all except epoch, $self->{epoch} [ $delta * $Mult{$key} ] \n";
    $self->{epoch} += $delta * $Mult{$key};
    # print "  STORE: epoch is $self->{epoch} ",join(':',gmtime($self->{epoch})),"\n";
    # remove all other keys (now invalid)
    %{$self} = ( epoch => $self->{epoch}, tz100 => $self->{tz100} );    
    return;
}

sub FETCH { 
    my ($self, $key) = @_; 
    # my $a = 0 + $self;
    # printf (" %0X ", $a);
    my ($value);
    $key = 'day' if $key eq 'monthday';
    # print "FETCH:  $key\n";

    if ($key eq 'tz') {
        # print "FETCH:  $key = $self->{tz100} \n";
        my ($h, $m) = (FETCH($self, 'tzhour'), FETCH($self, 'tzminute'));
        my $s = $self->{tz100} < 0 ? '-' : '+';
        # print "FETCH:  $key $self->{tz100} = $s $h $m \n";
        return $s . substr($h,1,2) . sprintf("%02d", abs($m));
    }
    if ($key eq 'tzhour') {
        my $s = $self->{tz100} < 0 ? '-' : '+';
        $value = int($self->{tz100} / 3600);
        return $s . sprintf("%02d", abs($value));
    }
    if ($key eq 'tzminute') {
        my $s = $self->{tz100} < 0 ? '-' : '+';
        $value = int ( ( $self->{tz100} - 3600 * int($self->{tz100} / 3600) ) / 60 );
        return $s . sprintf("%02d", abs($value));
    }

    unless (exists($self->{$key}) ) {
        # create key if possible
        if (( $key eq 'epoch') or not exists $self->{epoch} ) {
            # print "  FETCH: create epoch\n";
            my ($year, $month, $day, $hour, $minute, $second);
            $day =    exists $self->{day} ?    $self->{day}    : 1;
            $month =  exists $self->{month} ?  $self->{month} - 1   : 0;
            $year =   exists $self->{year} ?   $self->{year} - 1900 : 0;
            $hour =   exists $self->{hour} ?   $self->{hour}   : 0;
            $minute = exists $self->{minute} ? $self->{minute} : 0;
            $second = exists $self->{second} ? $self->{second} : 0;
            # print " ($year, $month, $day) \n";
            $self->{epoch} = timegm( $second, $minute, $hour, $day, $month, $year );
            return $self->{epoch} if $key eq 'epoch';  # ???
        }
        # print "  FETCH: create $key and others\n";
        (    $self->{second},  $self->{minute},    $self->{hour},
            $self->{day},     $self->{month},    $self->{year},
            $self->{weekday}, $self->{yearday} ) = gmtime($self->{epoch});
        $self->{year} += 1900;
        $self->{month}++;
        $self->{weekday} = 7 unless $self->{weekday};
        $self->{yearday}++;

        $self->{week} = int ( ($self->{yearday} - $self->{weekday} + 10) / 7 );
        if ($self->{yearday} > 361) {
            # print "  FETCH: week overflow\n";
            # find out next year's jan-04 weekday
            tie my %tmp, 'Date::Tie';
            # jan-04 weekday:  1  2  3  4  5  6  7
            my @wk1 = qw ( 28 29 30 31 32 26 27 28  );
            %tmp = ( year => ($self->{year} + 1), month => '01', day => '04' );
            my $last_day = $wk1[$tmp{weekday}];
            # print "  FETCH: 1st week ",$tmp{year},"-jan-04 is $tmp{weekday} - after dec-$last_day is W01\n";
            $self->{week} = 1 if ($self->{day} >= $last_day);
        }

        $self->{weekyear} = $self->{year};
        $self->{weekyear}++ if ($self->{week} < 2) and ($self->{month} > 2);
    } # create keys

    $value = $self->{$key};
    return $value if $key eq 'weekday';
    return sprintf("%02d", $value) if $key ne 'yearday';
    return sprintf("%03d", $value);

    # $value = '0' . $value if ($value >= 0) && ($value < 10) && ($key ne 'weekday');
    # $value = '0' . $value if (length($value) < 3) && ($key eq 'yearday');
    # return $value;
}

sub TIEHASH  { 
    # print "  TIE ", join(":", @_), "\n";
    my $self = bless {}, shift;
    my ($tmp1, $tmp2);
    $self->{tz100} = 0;
    ( $self->{second},  $self->{minute}, $self->{hour},
      $self->{day},     $self->{month},  $self->{year},
      $self->{weekday}, $self->{yearday} ) = gmtime();
    $self->{year} += 1900;
    $self->{month}++;
    $self->{weekday} = 7 unless $self->{weekday};
    $self->{yearday}++;
    while ($#_ > -1) {
        ($tmp1, $tmp2) = (shift, shift);
        # $self->{$tmp1} = $tmp2;
        STORE ($self, $tmp1, $tmp2);
    }
    return $self;
}

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    # print "  NEW\n";
    tie %$self, 'Date::Tie', @_;
    return $self;
}

# This is for debugging only !
# sub iso { my $self = shift; return $self->{year} . '-' . $self->{month} . '-' . $self->{day} . " $self->{weekyear}-W$self->{week}-$self->{weekday}"; }
# sub debug { return; my $self = shift; return join(':',%{$self}); }

1;

__END__

=head1 NAME

Date::Tie - ISO dates made easy

=head1 SYNOPSIS

    use Date::Tie;

    tie my %date, 'Date::Tie', year => 2001, month => 11, day => 9;
    $date{year}++;
    $date{month} += 12;    # 2003-11-09

    # you can also use OO syntax
    my $date = Date::Tie->new( year => 2001, month => 11, day => 9 );
    $date->{year}++;
    $date->{month} += 12;  # 2003-11-09

    $date{weekday} = 0;    # sunday at the start of this week
    $date{weekday} = 7;    # sunday at the end of this week
    $date{weekday} = 14;   # sunday next week 

    $date{tz} = '-0300';   # change timezone
    $date{tzhour}++;       # increment timezone

    # "next month's last day"
    $date{month}+=2;
    $date{day} = 0;        # this is actually a "-1" since days start in "1"

    # copy a date with timezone
    tie my %newdate, 'Date::Tie', tz => $date{tz}, epoch => $date{epoch};

=head1 DESCRIPTION

Date::Tie is an attempt to simplify date operations syntax.

Whenever a Date::Tie hash key receives a new value, it will change 
the other keys following the ISO date rules. 
For example: 

     print $a{hour}, ":", $a{minute};     #  00 59
     $a{minute}++;
     print $a{hour}, ":", $a{minute};     #  01 00

The default value of a new hash will be the current value of I<gmtime()>, with timezone C<+0000>.

=head1 HASH KEYS

Date::Tie manages a hash containing the keys: 
I<year>, I<month>, I<day>, I<hour>, I<minute>, I<second>,
I<yearday>, I<week>, I<weekday>, I<weekyear>, I<epoch>, I<tz>, I<tzhour>, I<tzminute>. 
All keys can read or written directly.

=over 4

=item I<year>, I<month>, I<day>, I<hour>, I<minute>, I<second>

These keys are just what they say. 

You can use B<I<monthday>> instead of I<day> if you want to make it clear
it is not a I<yearday> or a I<weekday>. 

=item I<yearday>, I<week>, I<weekday>, I<weekyear>

B<I<yearday>> is the day number in the year.

B<I<weekday>> is the day number in the week. I<weekday> C<1> is monday.

B<I<week>> is the week number in the year.

B<I<weekyear>> is the year number, when referring to a week of a year.
It is often I<not equal> to I<year>. 
Changing I<weekyear> will leave you with the same week and weekday, 
while changing I<year> will leave you with the same month and monthday.

=item I<epoch>, I<tz>, I<tzhour>, I<tzminute>

B<I<epoch>> is the local epoch. 

B<I<tz>> is the timezone as hundreds, like in C<-0030>. 
It is I<not always> the same as the expression
S<C<$date{tzhour} . $date{tzminute}>>, which in this case would be C<-00-30>.

Changing timezone (any of I<tz>, I<tzhour>, or I<tzminute>) changes I<epoch>.

=back

=head1 ISO 8601

I<Markus Kuhn> wrote a summary of ISO8601 
International Standard Date and Time Notation
in C<http://www.cl.cam.ac.uk/~mgk25/iso-time.html>

I<Day of year> starts with C<001>. 

I<Day of week> starts with C<1> and is a monday.

I<Week> starts with C<01> and is the first week of the
year that has a thursday. 
Week C<01> often begins in the previous year.

=head1 CAVEATS

Reading time zone C<-0030> with S<C<$date{tzhour} . $date{tzminute}>> gives C<-00-30>. 
Use I<tz> to get C<-0030>.

The order of setting hash elements is important. 
This is I<not> likely to make C<%b> equal to C<%d>:

    # copy all fields - may not work!
    tie my %b, 'Date::Tie', %d;

This is one way to make a copy of C<%d>: 

    # set timezone, then epoch
    tie my %b, 'Date::Tie', tz => $d{tz}, epoch => $d{epoch};

If you change I<month>, then I<day> will be adjusted to fit that month:

    $date = (month=>10, day=>31);
    $date{month}++;     #  month=>11, day=>30

If you need to know whether a hash is tied to Date::Tie use perl function I<tied()>

=head1 SEE ALSO

I<Date::Calc>, I<Date::Manip>, I<Class::Date>, and many other good date and time modules!

Date::Tie depends on I<Tie::Hash> and I<Time::Local>.

=head1 AUTHOR

Fl�vio Soibelmann Glock (fglock@pucrs.br)

=cut

TODO

    test fractions of seconds

    access environment for timezone initialization

    remove debugging code

    check if it actually needs $Infinity, %Mult, %Max, %Min

	make hash accept other values (behave like a normal hash)

HISTORY
       
    0.07 more POD
         examples don't use internal functions

    0.06 correct day overflow on month/year change
         more tests, examples

    0.05 POD format correction
         tzhour,tzminute is -00-30 instead of +00-30
         more tests

    0.04 yearday, weekday, week, weekyear
         better storage
         initializes to 'now'.
         timezones
         more tests
 
    0.03 STORE rewritten
         examples work

    0.02 Make it a real module

    0.01 I started this when dLux said:
        > What about this kind of syntax:
        > my $mydate = new XXXX::Date "2001-11-07";
        > # somewhere later in the code
        > my $duedate = $mydate + 14 * XXX::Date::DAY;
        > my $duedate = $mydate + 14 * DAY;
        > my $duedate = $mydate->add(12, DAYS);
        > my $duedate = $mydate->add(day => 12);
        > my $duedate = $mydate + "12 days";
        > my $duedate = $mydate + "12 days and 4 hours and 3 seconds"; # :-)

