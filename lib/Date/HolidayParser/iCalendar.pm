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

die('Not ready');

# Purpose: Enable iCalendar emulation
# Usage: obj->enable_ical_interface();
sub enable_ical_interface
{
	my $this = shift;
	$this->{ICAL} = true;
	$this->{UID_LIST} = {};
	return(true);
}

# Purpose: Return manager information
# Usage: get_manager_version();
sub get_manager_version
{
	my $this = shift;
	return(false) if not $this->{ICAL}; # Don't allow this to be enabled if we're not in iCalendar emulation mode
	return('01_capable');
}

# Purpose: Return manager capability information
# Usage: get_manager_capabilities
sub get_manager_capabilities
{
	# All capabilites as of 01_capable
	return(['LIST_DPI',])
}

# Purpose: Get an emulated UID
# Usage: get_info(UID);
sub get_info {
	my $this = shift;
	my $UID = shift;
	return($this->{UID_LIST}{$UID}) if $this->{UID_LIST}{$UID};
	return(false);
}

# Purpose: Generate an iCalendar entry
# Usage: this->_event_to_iCalendar(UNIXTIME, NAME);
sub _event_to_iCalendar
{
	my $this = shift;
	my $unixtime = shift;
	my $name = shift;
	# Generate the UID of the event, this is simply a 
	my $sum = unpack("%32C*", $name);
	# This should be unique enough for our needs.
	# We don't want it to be random, because if someone copies the events to their
	# own calendar, we want DP::iCalendar::Manager to fetch the information from
	# the changed calendar, instead of from the HolidayParser object.
	my $UID = 'D-HP-ICS-'.$unixtime.$name;
	
	$this->{UID_LIST}{$UID} = {
		UID => $UID,
		DTSTART => iCal_ConvertFromUnixTime($unixtime),
		DTEND => iCal_ConvertFromUnixTime($unixtime+86390), # Yes, this is purposefully not 86400
		SUMMARY => $name,
	};
	return($UID);
}

# Purpose: Get information for the supplied month (list of days there are events)
# Usage: my $TimeRef = $object->get_monthinfo(YEAR,MONTH,DAY);
sub get_monthinfo {
	my($this, $Year, $Month) = @_;	# TODO: verify that they are set
	$this->get($Year);
	my @Array;
	if(defined($this->{cache}{$Year}) and defined($this->{cache}{$Year}{$Month})){
		@Array = sort keys(%{$this->{cache}{$Year}{$Month}});
	}
	return(\@Array);
}

# Purpose: Get information for the supplied date (list of times in the day there are events)
# Usage: my $TimeRef = $object->get_dateinfo(YEAR,MONTH,DAY);
sub get_dateinfo {
	my($this, $Year, $Month, $Day) = @_;	# TODO: verify that they are set
	$this->get($Year);
	my @Array;
	if(defined($this->{cache}{$Year}) and defined($this->{cache}{$Year}{$Month}) and defined($this->{cache}{$Year}{$Month}{$Day})) {
		@Array = sort keys(%{$this->{cache}{$Year}{$Month}{$Day}});
	}
	return(\@Array);
}

# Purpose: Return an empty array, unsupported.
# Usage: my $UIDRef = $object->get_timeinfo(YEAR,MONTH,DAY,TIME);
sub get_timeinfo {
	my($this, $Year, $Month, $Day,$Time) = @_;
	return(undef) if not $Time eq 'DAY';
	$this->get($Year);
	if(defined($this->{cache}{$Year}) and defined($this->{cache}{$Year}{$Month}) and defined($this->{cache}{$Year}{$Month}{$Day})) {
		return($this->{cache}{$Year}{$Month}{$Day}{$Time});
	}
	return([]);
}

# Purpose: Return an empty array, unsupported.
# Usage: my $ArrayRef = $object->get_years();
sub get_years {
	return([]);
}

# Purpose: Get a list of months which have events (those with *only* recurring not counted)
# Usage: my $ArrayRef = $object->get_months();
sub get_months {
	my ($this, $Year) = @_;
	$this->get($Year);
	my @Array = sort keys(%{$this->{cache}{$Year}});
	return(\@Array);
}

sub exists {
	my $this = shift;
	my $UID = shift;
	return(true) if defined($this->{UID_LIST}{$UID});
	return(false);
}

sub set_prodid { }

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
