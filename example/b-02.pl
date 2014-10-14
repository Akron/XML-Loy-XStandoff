#!/usr/bin/env perl
use lib '../lib';
use strict;
use warnings;
use feature 'say';
use XML::Loy::Example::Morphemes;

my $doc = XML::Loy::Example::Morphemes->new('document');

my $m = $doc->morphemes;

$m->morpheme('The');
$m->morpheme('sun');
$m->morpheme('shine');
$m->morpheme('s');
$m->morpheme('bright');
$m->morpheme('er');

print $doc->to_pretty_xml;
