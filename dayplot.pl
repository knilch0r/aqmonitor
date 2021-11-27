#!/usr/bin/perl -w
#
# produces a png plot of daily data

use strict;

use GD;
use POSIX qw(fmod);

# data area size: 24*24 (=576, 24 px per hour) x; 300 y
# for axis: 1px axis line, up to 10px marks
# and a border of 1px all around

my $im = new GD::Image(24*24+11+2, 300+11+2);

# colors: background white
my $white = $im->colorAllocate(255, 255, 255);
# lgrey for spacers
my $lgrey = $im->colorAllocate(211, 211, 211);
my $llgrey = $im->colorAllocate(225, 225, 225);
# black for axis
my $black = $im->colorAllocate(0, 0, 0);
# red for temp
my $red = $im->colorAllocate(211, 0, 0);
# blue for hum TODO
my $blue = $im->colorAllocate(0, 0, 211);

# read in data
my $maxa;
my $mina;
my @data;

while (<>) {
	die "invalid data '$_'" unless /^(\d\d) (\d\d) (\d\d) ([0-9.]+)/;
	my ($h, $m, $s, $v) = ($1, $2, $3, $4);
	$maxa //= $v;
	$mina //= $v;
	$maxa = $v if ($v > $maxa);
	$mina = $v if ($v < $mina);
	push @data, [$h, $m, $s, $v];
}

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

my $sstart = $mina - POSIX::fmod($mina, $sstep) + $sstep;
for ( my $i = $sstart; $i < $maxa ; $i += $sstep ) {
	my $y = getyforval($i, $maxa, $mina);
	$im->line(7, $y, 12, $y, $black);
	$im->line(13, $y, getxforhms(24,0,0), $y, $llgrey);
}

my $bstart = $mina - POSIX::fmod($mina, $bstep) + $bstep;
for ( my $i = $bstart; $i < $maxa ; $i += $bstep ) {
	my $y = getyforval($i, $maxa, $mina);
	$im->line(2, $y, 12, $y, $black);
	$im->line(13, $y, getxforhms(24,0,0), $y, $lgrey);
}

# print data

$im->setThickness(2);
my ($lt, $lx, $ly);
for my $i (@data) {
	my ($h, $m, $s, $v) = @$i;
	my $x = getxforhms($h, $m, $s);
	my $y = getyforval($v, $maxa, $mina);
	my $t = $h*60+$m;
	$lt //= $t;
	$lx //= $x;
	$ly //= $y;
	if (abs($t-$lt) > 10) {
		$lx = $x;
		$ly = $y;
	}
	$im->line($lx, $ly, $x, $y, $red);
	$lx = $x;
	$ly = $y;
	$lt = $t;
}

binmode STDOUT;
print $im->png;


