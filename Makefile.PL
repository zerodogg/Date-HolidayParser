use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Date::HolidayParser',
    AUTHOR              => 'Eskild Hustvedt <zerodogg@cpan.org>',
    VERSION_FROM        => 'lib/Date/HolidayParser.pm',
    ABSTRACT_FROM       => 'lib/Date/HolidayParser.pm',
    PL_FILES            => {},
	PREREQ => {
		'Any::Moose' => 0,
	},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'bzip2 -9f', SUFFIX => 'bz2', },
    clean               => { FILES => 'Date-HolidayParser-*' },
);
