#!/usr/bin/env perl
use strict;

# mouse name:
# on FreeBSD the default mouse is 'sysmouse'
# on Linux you need to find the mouse name using 'xinput list' and paste 
#    the string into the $sysmouse variable
#my $sysmouse = 'sysmouse';
my $sysmouse = 'MLK SPEEDLINK RF Snappy';
# get output of "xinput list"
my $xinp = `xinput list`;
# get the sysmouse id
(my $smid) = $xinp =~ /^.*$sysmouse\s+id=(\d)\s+.*$/gm;
# now get info for sysmouse device
print "System mouse ID is: $smid\n";
$xinp = `xinput list $smid`;
# get the information in the "Button labels" line
(my $bl) = $xinp =~ /^\s+Button labels:\s(.*)$/gm;
print "Button labels are: $bl\n";
# separate the button descriptions
my @btnt = split(/\"\s\"/, $bl);
# now get the button map
my @bmap = split(' ', `xinput get-button-map $smid`);
# build the command string to be executed
my $cmd = "xinput set-button-map $smid";
for (my $bid = 0; $bid < scalar @bmap; $bid++) {
  $cmd .= ' ' . ($btnt[$bid] =~ /.*Wheel.*/ ? '0' : $bmap[$bid]);
}
# finally turn off the wheels :)
print "Executed to turn wheel off: $cmd\n";
`$cmd`;
