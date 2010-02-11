#!perl
use strict;
use warnings;
use Test::More;
use Date::HolidayParser;
use FindBin;
require $FindBin::RealBin.'/basicTest.pm';

plan tests => 26;

my $parser = Date::HolidayParser->new("$FindBin::RealBin/testholiday");

ok(defined $parser, "->new returned something usable");
isa_ok($parser,'Date::HolidayParser');

runTests($parser);

1;
