#!/usr/bin/env perl
use lib 'lib', '../lib';
use XML::Loy::XStandoff;

# Create new corpus
my $cd = XML::Loy::XStandoff->new('corpusData');

# Define the meta data as external file
$cd->meta(uri => 'files/meta.xml');

# Retrieve the meta data, resulting in a new XML::Loy object
my $meta = $cd->meta(as => [-Loy, -DublinCore]);

print $meta->to_pretty_xml;

# Extension is available in the newly defined object
print $meta->at('Description')->dc('title');

