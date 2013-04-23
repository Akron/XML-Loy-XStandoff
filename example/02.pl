#!/usr/bin/env perl
use lib '../lib', 'lib';

use XML::Loy::AnaWiki::DocumentStructure;
my $ds = XML::Loy::AnaWiki::DocumentStructure->new('doc');
my $p = $ds->ds_para('First Paragraph Comment');
$p->ds_sentence("First sentence");
$p->ds_sentence("Second sentence");
$p->ds_sentence({ 'xml:id' => 's-3' } => "Final sentence");

print $ds->to_pretty_xml;
