#!/usr/bin/perl -w
#
# produces a png plot of daily data

use strict;

use GD;
use POSIX qw(fmod);

# data area size: 24*24 (=576, 24 px per hour) x; 300 y
# for axis: 1px axis line, up to 10px marks
# and a border of 1px all around

my $im = new GD::Image(24*24+11+11+2, 300+11+2);

# colors: background white
my $white = $im->colorAllocate(255, 255, 255);
# lgrey for spacers
my $lgrey = $im->colorAllocate(211, 211, 211);
my $llgrey = $im->colorAllocate(225, 225, 225);
# black for axis
my $black = $im->colorAllocate(0, 0, 0);
# red for first axis
my $red = $im->colorAllocate(190, 0, 0);
# blue for second axis
my $blue = $im->colorAllocate(90, 90, 255);

# read in data
my ($maxa, $mina, $maxb, $minb);
my @data;

my $aname = shift (@ARGV) // 'A';
my $aunit = shift (@ARGV) // '';
my $bname = shift (@ARGV) // 'B';
my $bunit = shift (@ARGV) // '';

while (<>) {
	die "invalid data '$_'" unless /^(\d\d) (\d\d) (\d\d) ([0-9.]+)( ([0-9.]+))?/;
	my ($h, $m, $s, $va, $vb) = ($1, $2, $3, $4, $6);
	$maxa //= $va;
	$mina //= $va;
	$maxa = $va if ($va > $maxa);
	$mina = $va if ($va < $mina);
	if (defined $vb) {
		$maxb //= $vb;
		$minb //= $vb;
		$maxb = $vb if ($vb > $maxb);
		$minb = $vb if ($vb < $minb);
	}
	push @data, [$h, $m, $s, $va, $vb];
}

die "no data supplied" unless (@data);

# draw x axis

$im->line(12, 302, 576+12, 302, $black);

sub getxforhms($$$) {
	my ($h, $m, $s) = @_;
	my $dx = ($h*24) + (($m*60 + $s) * 24 + 1800) / 3600;
	return int($dx) + 12;
}

# hours
for my $i (0..24) {
	my $x = getxforhms($i, 0, 0);
	$im->line($x, 302, $x, 312, $black);
	$im->line($x, 2, $x, 301, $lgrey);
}

# markers
for my $i (0,6,12,18,24) {
	my $x = getxforhms($i, 0, 0);
	$im->line($x, 2, $x, 301, $black);
}

# half-hours
for my $i (0..23) {
	my $x = getxforhms($i, 30, 0);
	$im->line($x, 302, $x, 307, $black);
	$im->line($x, 2, $x, 301, $llgrey);
}

my $MAXX = getxforhms(24,0,0);

# draw y axis

sub getyforval($$$) {
	my ($v, $max, $min) = @_;
	my $r = $max - $min;
	my $dy = (($v - $min) * 300 + $r/2) / $r;
	return 301 - int($dy);
}

my $rnga = $maxa - $mina;
my $bstep = int(10**int(log($rnga)/log(10)));
my $sstep = $bstep / 10;

print STDERR "$aname min: $mina, max: $maxa, step $bstep $aunit\n";

my $sstart = $mina - POSIX::fmod($mina, $sstep) + $sstep;
for ( my $i = $sstart; $i < $maxa ; $i += $sstep ) {
	my $y = getyforval($i, $maxa, $mina);
	$im->line(7, $y, 12, $y, $black);
	$im->line(13, $y, $MAXX, $y, $llgrey);
}

my $bstart = $mina - POSIX::fmod($mina, $bstep) + $bstep;
for ( my $i = $bstart; $i < $maxa ; $i += $bstep ) {
	my $y = getyforval($i, $maxa, $mina);
	$im->line(2, $y, 12, $y, $black);
	$im->line(13, $y, $MAXX, $y, $lgrey);
}

# draw second y axis if there were values
if (defined $maxb) {

	my $rngb = $maxb - $minb;
	$bstep = int(10**int(log($rngb)/log(10)));
	$sstep = $bstep / 10;

	print STDERR "$bname min: $minb, max: $maxb, step $bstep $bunit\n";

	my $sstart = $minb - POSIX::fmod($minb, $sstep) + $sstep;
	for ( my $i = $sstart; $i < $maxb ; $i += $sstep ) {
		my $y = getyforval($i, $maxb, $minb);
		$im->line($MAXX, $y, $MAXX+5, $y, $black);
	}

	my $bstart = $minb - POSIX::fmod($minb, $bstep) + $bstep;
	for ( my $i = $bstart; $i < $maxb ; $i += $bstep ) {
		my $y = getyforval($i, $maxb, $minb);
		$im->line($MAXX, $y, $MAXX+10, $y, $black);
	}

} # if second axis

# print data

$im->setThickness(2);
my ($lt, $lx, $lya, $lyb);
for my $i (@data) {
	my ($h, $m, $s, $va, $vb) = @$i;
	my $x = getxforhms($h, $m, $s);
	my $ya = getyforval($va, $maxa, $mina);
	my $yb;
	if (defined $maxb) {
		$yb = getyforval($vb, $maxb, $minb);
	}
	my $t = $h*60+$m;
	$lt //= $t;
	$lx //= $x;
	$lya //= $ya;
	$lyb //= $yb;
	if (abs($t-$lt) > 10) {
		$lx = $x;
		$lya = $ya;
		$lyb = $yb;
	}
	if (defined $maxb) {
		$im->line($lx, $lyb, $x, $yb, $blue);
	}
	$im->line($lx, $lya, $x, $ya, $red);
	$lx = $x;
	$lya = $ya;
	$lyb = $yb;
	$lt = $t;
}

binmode STDOUT;
print $im->png;


