#!/usr/bin/env perl
use lib '../lib';
use strict;
use warnings;
use feature 'say';
use XML::Loy::XStandoff;

# Create new corpusData
my $cd = XML::Loy::XStandoff->new('corpusData');

# Load extensions for Morphemes and Syllables
$cd->extension(-Example::Morphemes, -Example::Syllables);

# Set textual content embedded
$cd->textual_content('The sun shines brighter.');

# Create segmentation
my $seg = $cd->segmentation;

my $all = $seg->segment(0, 24);

# Create new annotation layer for morphemes
my $m = $cd->layer->morphemes;
$m->seg($all);

# Create and associate all necessary segments for all morphemes
foreach ([0,3], [4,7], [8,13], [13,14], [15,21], [21,23]) {
  $m->morpheme->seg($seg->segment($_->[0], $_->[1]));
};

# Create new annotation layer for syllables
my $s = $cd->layer->syllables;
$s->seg($all);

# Create and associate all necessary segments for all syllables
# independently, so overlaps are supported
foreach ([0,3], [4,7], [8,14], [15,20], [20,23]) {
  $s->syllable->seg($seg->segment($_->[0], $_->[1]));
};

# Change the content of the second morpheme
$cd->find('morpheme')->[1]->segment_content('moon');

print $cd->to_pretty_xml;

__END__

my $seg1 = $seg->segment(0,24);
my $seg2 = $seg->segment(0, 3);
my $seg3 = $seg->segment(4, 7);
my $seg4 = $seg->segment(8, 13);
my $seg5 = $seg->segment(13, 14);
my $seg6 = $seg->segment(15, 21);
my $seg7 = $seg->segment(21, 23);




