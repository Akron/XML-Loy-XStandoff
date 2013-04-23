#!/usr/bin/env perl
use lib '../lib', 'lib';

use XML::Loy;

my $doc = XML::Loy->new(<<'XML');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<html>
  <head><title>My Document</title></head>
  <body>
    <h1>My Title</h1>
  </body>
</html>
XML

$doc->extension(-AnaWiki::DocumentStructure);
my $p = $doc->at('body')->ds_para;
$p->ds_sentence('First senence');
$p->ds_sentence('Second sentence');

print $doc->to_pretty_xml;
