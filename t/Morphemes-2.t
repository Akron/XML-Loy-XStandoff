#!/usr/bin/env perl
use lib 'lib', '../lib';
use Test::More;
use_ok('XML::Loy');
use_ok('XML::Loy::Example::Morphemes');

my $doc = XML::Loy->new(<<'XML');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<html>
  <head><title>The sun</title></head>
  <body />
</html>
XML

is($doc->at('title')->text, 'The sun', 'Text');

$doc->extension(-Example::Morphemes);
my $p = $doc->at('body')->add(
  'p' => 'The sun shines'
);
my $m = $p->morphemes;
$m->morpheme('bright');
$m->morpheme('er');

# print $doc->to_pretty_xml;
done_testing;
