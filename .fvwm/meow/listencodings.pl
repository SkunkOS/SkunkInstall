#!/usr/local/bin/perl
use strict;
use warnings;
use diagnostics;
use utf8;

use Encode;

  print "Loaded Encodings\n";
  my @list = Encode->encodings();
  foreach (@list) {
    print "$_\n";
  }
  print "Available Encodings\n";

  my @all_encodings = Encode->encodings(":all");
  foreach (@all_encodings) {
    print "$_\n";
  }
