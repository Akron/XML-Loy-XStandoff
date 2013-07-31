#!/usr/bin/env perl
use lib '../lib';
use strict;
use warnings;
use feature 'say';
use XML::Loy::XStandoff;

# Create new corpusData
my $cd = XML::Loy::XStandoff->new('corpusData');

# Set textual content embedded
$cd->textual_content('The sun shines brighter.');

# Create segmentation
my $seg = $cd->segmentation;

# Create segments manually
my $seg1 = $seg->segment(0,24);
my $seg2 = $seg->segment(0, 3);
my $seg3 = $seg->segment(4, 7);
my $seg4 = $seg->segment(8, 13);
my $seg5 = $seg->segment(13, 14);
my $seg6 = $seg->segment(15, 21);
my $seg7 = $seg->segment(21, 23);

print $cd->to_pretty_xml;


# Get segment content
say $seg->segment($seg3)->segment_content;
# 'sun'

# Replace segment content
$seg->segment($seg3)->segment_content('moon');

# Interactively replace segment content
$seg->segment($seg7)->segment_content( sub {
  my $t = shift;
  $t =~ s/er//;
  return $t;
});

# Show updated textual content
say $cd->textual_content;
# The moon shines bright

# Segment positions are updated automatically
for ($seg->segment($seg6)) {
  say $_->attrs('start'); # 16
  say $_->attrs('end');   # 22
};
