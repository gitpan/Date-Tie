use Date::Tie;

my $test = 1;
tie my %d, 'Date::Tie';

sub test {
	if ($_[0] ne $_[1]) {
		print "not ok $test # $_[0] : $_[1]\n";
	}
	else {
		print "ok $test\n";
	}
	$test++;
}

print "1..18\n";

$d{year} = 2001;
$d{month} = 10;
$d{day} = 20;
test "$d{year}$d{month}$d{day}", "20011020";

$d{hour} = 10;
$d{minute} = 11;
$d{second} = 12;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "20011020T101112";

$d{epoch}++;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "20011020T101113";

$d{week}++;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "20011027T101113";
test "$d{weekyear}W$d{week}$d{weekday}T$d{hour}$d{minute}$d{second}", "2001W436T101113";

$d{weekyear}++;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "20021026T101113";
test "$d{weekyear}W$d{week}$d{weekday}T$d{hour}$d{minute}$d{second}", "2002W436T101113";

$d{year} = 1997;
$d{week} = 1;
$d{weekday} = 1;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "19961230T101113";
test "$d{weekyear}W$d{week}$d{weekday}T$d{hour}$d{minute}$d{second}", "1997W011T101113";
$d{day}++;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "19961231T101113";
test "$d{weekyear}W$d{week}$d{weekday}T$d{hour}$d{minute}$d{second}", "1997W012T101113";

$d{tzhour} = -3;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tzhour}:$d{tzminute}", "19961231T071113 -03:00";

$d{tzhour} = 0;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tzhour}:$d{tzminute}", "19961231T101113 +00:00";

$d{tzhour} = 3;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tzhour}:$d{tzminute}", "19961231T131113 +03:00";

$d{tz} = '-0030';
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tz}", "19961231T094113 -0030";

$d{tzminute} += 5;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tz}", "19961231T094613 -0025";

$d{tz} = '+0000';
$d{hour} = 23;
$d{day} = 31;
$d{tz} = '-0200';
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tz}", "19961231T211113 -0200";

$d{tz} = '+0200';
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{tz}", "19970101T011113 +0200";

1;