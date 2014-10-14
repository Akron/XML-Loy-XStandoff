#!/usr/bin/env perl
use lib '../lib', 'lib';

use XML::Loy;

my $doc = XML::Loy->new('document');

$doc->set(title => 'My Title');
$doc->set(title => 'My New Title');
$doc->add(paragraph => { id => 'p-1' } => 'First Paragraph');
$doc->add(paragraph => { id => 'p-2' } => 'Second Paragraph');

print $doc->to_pretty_xml;
