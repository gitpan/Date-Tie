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

print "1..22\n";

$d{year} = 2001;
$d{month} = 10;
$d{day} = 20;
test "$d{year}$d{month}$d{day}", "20011020";

$d{hour} = 10;
$d{minute} = 11;
$d{second} = 12;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second}", "20011020T101112";

# is fraction initialized to zero?
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{frac}", "20011020T101112 .0";

$d{frac} = 0.123;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{frac}", "20011020T101112 .123";
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}" . ( $d{second} + $d{frac} ), 
     "20011020T101112.123";

$d{frac} += 0.4;  # positive
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute}$d{second} $d{frac}", "20011020T101112 .523";

$d{frac} += 0.7;  # positive overflow
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1011 13 .223";

$d{frac} -= 0.7;   # negative
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1011 12 .523";

$d{frac} -= 15.4;  # negative overflow
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1010 57 .123";

$d{frac} -= 117.123;  # negative overflow
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1009 00 .0";

$d{frac} += 3600;   # integer
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1109 00 .0";

$d{frac} += 3600.00112233;   # big overflow, high precision
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1209 00 .00112233";

# setting fractional seconds through {second} will not work
$d{second} = 14.56;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1209 14 .00112233";
$d{frac} += 0.1;  # test mixing frac and second
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1209 14 .10112233";

# overflowing frac goes to second
$d{frac} = 1;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011020T1209 15 .0";

$d{frac} = 0.1;

# fractional day, etc are ignored
$d{day} += 1.3;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011021T1209 15 .1";
$d{month} += 1.3;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20011121T1209 15 .1";
$d{year} += 1.3;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20021121T1209 15 .1";

# fractional epoch is ignored
$d{epoch} += 1.3;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20021121T1209 16 .1";

# fractional minute, hour are ignored
$d{hour} += 1.3;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20021121T1309 16 .1";
$d{minute} += 1.3;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20021121T1310 16 .1";

# fractional timezone is ignored
$d{tz} += 100.3;
test "$d{year}$d{month}$d{day}T$d{hour}$d{minute} $d{second} $d{frac}", "20021121T1410 16 .1";

1;
