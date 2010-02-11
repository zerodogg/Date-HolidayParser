#!/usr/bin/perl
# Date::HolidayParser
# A parser of ~/.holiday-style files.
#  The format is based off of the holiday files found bundled
#  with the plan program, not any official spec. This because no
#  official spec could be found.
# Copyright (C) Eskild Hustvedt 2006, 2007, 2008, 2010
#
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself. There is NO warranty;
# not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# This is the iCalendar component, which emulates a DP::iCalendar-like interface
# in order to make it easier to use for users familiar with iCalendar, and
# make it compatible with DP::iCalendar::Manager.

package Date::HolidayParser::iCalendar;

use Moose;
use Date::HolidayParser;
use constant { true => 1, false => 0 };

extends 'Date::HolidayParser';

has '_UID_List' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub { {} },
);
has '_iCal_cache' => (
	is => 'rw',
	isa => 'HashRef',
	default => sub { {} },
);

# -- Public methods --

# Purpose: Get an iCalendar hash with holiday info matching the supplied UID
# Usage: get_info(UID);
sub get_info
{
	my $self = shift;
	my $UID = shift;
	return($self->_UID_List->{$UID}) if $self->_UID_List->{$UID};
	return(false);
}

# Purpose: Get information for the supplied month (list of days there are events)
# Usage: my $TimeRef = $object->get_monthinfo(YEAR,MONTH,DAY);
sub get_monthinfo
{
	my($self, $Year, $Month) = @_;	# TODO: verify that they are set
	$self->get($Year);
	my @Array;
	if(defined($self->_iCal_cache->{$Year}) and defined($self->_iCal_cache->{$Year}{$Month})){
		@Array = sort keys(%{$self->_iCal_cache->{$Year}{$Month}});
	}
	return(\@Array);
}

# Purpose: Get information for the supplied date (list of times in the day there are events)
# Usage: my $TimeRef = $object->get_dateinfo(YEAR,MONTH,DAY);
sub get_dateinfo
{
	my($self, $Year, $Month, $Day) = @_;	# TODO: verify that they are set
	$self->get($Year);
	my @Array;
	if(defined($self->_iCal_cache->{$Year}) and defined($self->_iCal_cache->{$Year}{$Month}) and defined($self->_iCal_cache->{$Year}{$Month}{$Day})) {
		@Array = sort keys(%{$self->_iCal_cache->{$Year}{$Month}{$Day}});
	}
	return(\@Array);
}

# Purpose: Return an empty array, unsupported.
# Usage: my $UIDRef = $object->get_timeinfo(YEAR,MONTH,DAY,TIME);
sub get_timeinfo
{
	my($self, $Year, $Month, $Day,$Time) = @_;

	return(undef) if not $Time eq 'DAY';

	$self->get($Year);

	if( defined($self->_iCal_cache->{$Year}) and
		defined($self->_iCal_cache->{$Year}{$Month}) and
		defined($self->_iCal_cache->{$Year}{$Month}{$Day})
	)
	{
		return($self->_iCal_cache->{$Year}{$Month}{$Day}{$Time});
	}
	return([]);
}

# Purpose: Get a list of months which have events (those with *only* recurring not counted)
# Usage: my $ArrayRef = $object->get_months();
sub get_months
{
	my ($self, $Year) = @_;
	$self->get($Year);
	my @Array = sort keys(%{$self->_iCal_cache->{$Year}});
	return(\@Array);
}

# Purpose: Check if there is an holiday event with the supplied UID
# Usage: $bool = $object->exists($UID);
sub exists
{
	my $self = shift;
	my $UID = shift;
	return(true) if defined($self->_UID_List->{$UID});
	return(false);
}

# -- Unsupported or dummy methods, here for compatibility --

# Purpose: Return an empty array, unsupported.
# Usage: my $ArrayRef = $object->get_years();
sub get_years
{
	return([]);
}

# -- DP::iCalendar compatibility code --

# Used by DP::iCalendar::Manager to set the prodid in output iCalendar files.
# We can't output iCalendar files, so we just ignore calls to it.
sub set_prodid { }

# Purpose: Return manager information
# Usage: get_manager_version();
sub get_manager_version
{
	my $self = shift;
	return('01_capable');
}

# Purpose: Return manager capability information
# Usage: get_manager_capabilities
sub get_manager_capabilities
{
	# All capabilites as of 01_capable
	return(['LIST_DPI',])
}


# -- Private methods --

# Purpose: Wraps _addParsedEvent in Date::HolidayParser so that an iCalendar version
# 	is also created at the same time.
around '_addParsedEvent' => sub
{
	my $orig = shift;
	my $self = shift;

	my($FinalParsing,$final_mon,$final_mday,$HolidayName,$holidayType,$FinalYDay,$PosixYear) = @_;

	my $UID = $self->_event_to_iCalendar(POSIX::mktime(0, 0, 0, $FinalYDay, 0, $PosixYear),$HolidayName);
	my $Year = $PosixYear+1900;

	if(not $self->_iCal_cache->{$Year}->{$final_mon}{$final_mday}{'DAY'})
	{
		$self->_iCal_cache->{$Year}->{$final_mon}{$final_mday}{'DAY'} = [];
	}
	push(@{$self->_iCal_cache->{$Year}->{$final_mon}{$final_mday}{'DAY'}}, $UID);

	return $self->$orig(@_);
};

# Purpose: Generate an iCalendar entry
# Usage: this->_event_to_iCalendar(UNIXTIME, NAME);
sub _event_to_iCalendar
{
	my $self = shift;
	my $unixtime = shift;
	my $name = shift;
	# Generate the UID of the event, this is simply a 
	my $sum = unpack("%32C*", $name);
	# This should be unique enough for our needs.
	# We don't want it to be random, because if someone copies the events to their
	# own calendar, we want DP::iCalendar::Manager to fetch the information from
	# the changed calendar, instead of from the HolidayParser object.
	my $UID = 'D-HP-ICS-'.$unixtime.$name;
	
	$self->_UID_List->{$UID} = {
		UID => $UID,
		DTSTART => iCal_ConvertFromUnixTime($unixtime),
		DTEND => iCal_ConvertFromUnixTime($unixtime+86390), # Yes, this is purposefully not 86400
		SUMMARY => $name,
	};
	return($UID);
}

# The following three functions are originally from DP::iCalendar

# Purpose: Generate an iCalendar date-time from multiple values
# Usage: my $iCalDateTime = iCal_GenDateTime(YEAR, MONTH, DAY, TIME);
sub iCal_GenDateTime {
	# NOTE: This version ignores $Time because it isn't used in HolidayParser
	my ($Year, $Month, $Day, $Time) = @_;
	# Fix the month and day
	my $iCalMonth = _PrefixZero($Month);
	my $iCalDay = _PrefixZero($Day);
	return("$Year$iCalMonth$iCalDay");
}

# Purpose: Generate an iCalendar date-time string from a UNIX time string
# Usage: my $iCalDateTime = iCal_ConvertFromUnixTime(UNIX TIME);
sub iCal_ConvertFromUnixTime {
	my $UnixTime = shift;
	my ($realsec,$realmin,$realhour,$realmday,$realmonth,$realyear,$realwday,$realyday,$realisdst) = localtime($UnixTime);
	$realyear += 1900;	# Fix the year
	$realmonth++;		# Fix the month
	# Return data from iCal_GenDateTime
	return(iCal_GenDateTime($realyear,$realmonth,$realmday,"$realhour:$realmin"));
}

# Purpose: Prefix a "0" to a number if it is only one digit.
# Usage: my $NewNumber = PrefixZero(NUMBER);
sub _PrefixZero {
	if ($_[0] =~ /^\d$/) {
		return("0$_[0]");
	}
	return($_[0]);
}

# End of Date::HolidayParser::iCalendar
1;
