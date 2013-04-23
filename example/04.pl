#!/usr/bin/env perl
use lib 'lib', '../lib';
use XML::Loy::XStandoff;

# Create new corpus
my $corpus = XML::Loy::XStandoff->new('corpus');

# Create corpusData and primaryData
my $cd = $corpus->corpus_data(id => 'my-corpus-data');
my $pd = $cd->primary_data(id => 'my-primary-data');


# Set textual content embedded
$pd->textual_content('Give me the hammer!');

# Create segments manually
my $seg1 = $pd->segment(0, 19);
my $seg2 = $pd->segment(0, 4);
my $seg3 = $pd->segment(5, 7);
my $seg4 = $pd->segment(8, 11);
my $seg5 = $pd->segment(12, 18);

# print $corpus->to_pretty_xml;

# Get segment content
print $pd->segment($seg3)->segment_content;
# me

# Replace segment content
$pd->segment($seg3)->segment_content('him');

# Interactively replace segment content
$pd->segment($seg5)->segment_content(
  sub {
    return ucfirst $_[0];
  });

# Show updated textual content
print $pd->textual_content;
# Give him the Hammer!

# Segments were updated automatically
print $pd->segment($seg5)->segment_content;
# Hammer
