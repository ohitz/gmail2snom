#!/usr/bin/perl
#
# Allows to convert a google.csv file for import into a Snom 870
# phone.
#
# Copyright (C) 2014 Oliver Hitz <oliver@net-track.ch>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston,
# MA 02111-1307, USA.

use Text::CSV;
use strict;

if ($#ARGV != 1) {
  usage();
}

my $file_in = $ARGV[0];
my $file_out = $ARGV[1];

my $csv_in = Text::CSV->new({ binary => 1 });
my $csv_out = Text::CSV->new();

my $fh_in;
my $fh_out;

if (!open $fh_in, "<:raw:encoding(utf16)", $file_in) {
  print STDERR "Unable to open $file_in!\n";
  exit 1;
}
# First row contains column names.
my $row = $csv_in->getline($fh_in);
$csv_in->column_names($row);

if (!open $fh_out, ">:encoding(utf8)", $file_out) {
  print STDERR "Unable to create $file_out!\n";
  exit 1;
}
$csv_out->combine("Name", "Number", "Contact Type", "Outgoing Identity", "First Name", "Family Name", "Favorite");
print $fh_out $csv_out->string()."\n";

while (my $row = $csv_in->getline_hr($fh_in)) {
  my $organization = $row->{"Organization 1 - Name"};
  my $family_name = $row->{"Family Name"};
  my $given_name = $row->{"Given Name"};

  my $name = "";

  if ($organization ne "") {
    $name = $organization;
    if ($family_name ne "") {
      $name .= " - ";
      $name .= $family_name;
      
      if ($given_name ne "") {
	$name .= " ".$given_name;
      }
    }
  } else {
    $name = $family_name;
    if ($given_name ne "") {
      $name .= " ".$given_name;
    }
  }

  # Check for phone numbers.
  my $numbers = {};
  
  if ($row->{"Phone 1 - Value"} ne "") {
    $numbers->{$row->{"Phone 1 - Type"}} = translate_number($row->{"Phone 1 - Value"});
  }
  if ($row->{"Phone 2 - Value"} ne "") {
    $numbers->{$row->{"Phone 2 - Type"}} = translate_number($row->{"Phone 2 - Value"});
  }
  if ($row->{"Phone 3 - Value"} ne "") {
    $numbers->{$row->{"Phone 3 - Type"}} = translate_number($row->{"Phone 3 - Value"});
  }

  my $starred = "false";
  if ($row->{"Group Membership"} =~ /\* Starred/) {
    $starred = "true";
  }

  if (1 == scalar(keys %{ $numbers })) {
    # Single number.
    my $main_number = (values %{ $numbers })[0];

    $csv_out->combine($name,
		      $main_number,
		      "sip",
		      "active",
		      "",
		      "",
		      $starred);
    print $fh_out $csv_out->string."\n";

  } elsif (1 < scalar(keys %{ $numbers })) {
    # Multiple numbers.
    my $main_number = (values %{ $numbers })[0];

    $csv_out->combine($name,
		      $main_number,
		      "MASTER",
		      "active",
		      "",
		      "",
		      "false");
    print $fh_out $csv_out->string."\n";

    if (0 < scalar(keys %{ $numbers })) {
      foreach my $type (keys %{ $numbers }) {
	$csv_out->combine($type,
			  $numbers->{$type},
			  "sip",
			  "active",
			  "Member_alias",
			  $main_number,
			  $starred);
	print $fh_out $csv_out->string."\n";
      }
    }
  } else {
    # No number - filter this contact.
  }

}
$csv_in->eof or $csv_in->error_diag();
close $fh_in;
close $fh_out;

exit 0;

# Translate international to national numbers.
sub translate_number {
  my $number = shift;
  $number =~ s/^\+41/0/;
  $number =~ s/^\+/00/;
  return $number;
}

sub usage()
{
  print STDERR "Usage: $0 google.csv snom.csv\n";
  exit 1;
}
