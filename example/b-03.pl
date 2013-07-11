#!/usr/bin/env perl
use lib '../lib';
use strict;
use warnings;
use feature 'say';

use XML::Loy;

my $doc = XML::Loy->new(<<'XML');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<html>
  <head><title>The sun</title></head>
  <body />
</html>
XML

$doc->extension(-Example::Morphemes);
my $p = $doc->at('body')->add('p' => 'The sun shines');
my $m = $p->morphemes;
$m->morpheme('bright');
$m->morpheme('er');

print $doc->to_pretty_xml;
