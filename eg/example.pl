#/bin/perl
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Date::Tie;
tie %a, 'Date::Tie';
print Date::Tie::iso(\%a),"\n";

# example 1
    tie %date, 'Date::Tie';
	%date = ( year => 2001, month => 11, day => '09' );
	$date{year}++;
	$date{month} += 12;
print Date::Tie::iso(\%date),"\n";   # 2003-11-09

# example 2
	$date = Date::Tie->new( year => 2001, month => 11, day => '09' );
	$date->{year}++;
	$date->{month} += 12;  # 2003-11-09
print Date::Tie::iso($date),"\n";   # 2003-11-09

# example 3
    tie %a, 'Date::Tie';
	($a{hour}, $a{minute}) = (0, 59);
	print $a{hour}, ":", $a{minute};     #  00 59
	$a{minute}++;
	print $a{hour}, ":", $a{minute};     #  01 00


$a = Date::Tie->new(day=>2);
print "a = ",$a->{day},"\n";
$a->{day}++;
print "a = ",$a->{day},"\n";
$b = $a;
print "b = ",$b->{day},"\n";
$a->{hour} = 10;
print "a = ",$a->iso,"\n";
$a->{minute} = 30;
print "a = ",$a->iso,"\n";
$a->{year} = 2001;
print "a = ",$a->iso,"\n";
$a->{month} += 12;
print "a = ",$a->iso,"\n";
$a->{day} += 30;
print "a = ",$a->iso,"\n";

print "a = ",$a->{epoch},"\n";
$a->{day}++;
$a->{year} = 2001;
$a->{month} += 20;
$a->{day} += 400;
print "a = ",$a->{epoch},"\n";

1;
