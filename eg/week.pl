#/bin/perl
# Copyright (c) 2001 Flavio Soibelmann Glock. All rights reserved.
# This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

use Date::Tie;
$| = 1;
    tie %date, 'Date::Tie';
print Date::Tie::iso(\%date),"\n";
	%date = ( year => 2001, month => 12, day => 31 );
print Date::Tie::iso(\%date),"\n";
print "Week day: $date{weekday}\n"; 

$date{weekday}++;
print Date::Tie::iso(\%date),"\n";
$date{week}++;
print Date::Tie::iso(\%date),"\n";

$date{year} = 1976;
$date{weekday} = 1;
$date{week} = 1;
print Date::Tie::iso(\%date),"\n";

$date{weekyear}++;
print Date::Tie::iso(\%date),"\n";

$date{weekyear}-=2;
print Date::Tie::iso(\%date),"\n";

$date{yearday} = 32;
print Date::Tie::iso(\%date),"\n";

$date{yearday}--;
print Date::Tie::iso(\%date),"\n";

$date{weekday} = 7;
print Date::Tie::iso(\%date),"\n";

$date{weekday} = 0;
print Date::Tie::iso(\%date),"\n";

$date{weekday} = -7;
print Date::Tie::iso(\%date),"\n";

	$date{year}++;
print Date::Tie::iso(\%date),"\n";
	$date{month} += 12;
print Date::Tie::iso(\%date),"\n";

1;
