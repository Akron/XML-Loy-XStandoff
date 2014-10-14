#!/usr/bin/env perl
use lib 'lib', '../lib';
use Test::More;
use_ok('XML::Loy');
use_ok('XML::Loy::AnaWiki::DocumentStructure');

ok(my $ds = XML::Loy::AnaWiki::DocumentStructure->new('doc'), 'New doc');

my $p = $ds->ds_para('First Paragraph Comment');
$p->ds_sentence("That's my first sentence");
$p->ds_sentence("And my second sentence");
$p->ds_sentence({ 'xml:id' => 's-3' } => "My final sentence");

is($p->ds_sentence(pos => 2)->text, 'And my second sentence', 'Second sentence');
is($p->ds_sentence(id => 's-3')->text, 'My final sentence', 'Last sentence');

# diag $ds->to_pretty_xml;

my $s = $p->ds_sentence;
ok($s->ds_word('Elephant'), 'Set Elephant');

my $doc = XML::Loy->new(<<'XML');
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<html>
  <head><title>My Example</title></head>
  <body>
    <h1>Here's my document:</h1>
  </body>
</html>
XML

$doc->extension('-AnaWiki::DocumentStructure');

my $p = $doc->at('body')->ds_para;
$p->ds_sentence('Hello World');
$p->ds_sentence('Example sentence');

is($p->ds_sentence(pos => 1)->text, 'Hello World', 'First sentence');
is($p->ds_sentence(pos => 2)->text, 'Example sentence', 'Example sentence');

done_testing;

__END__




ok(my $p = $doc->ds_para, 'New Paragraph');
ok($p->ds_sentence("That's a new sentence"), 'Add sentence');

$p->ds_sentence('Next Sentence');


# ('xml:id' => 'p-1')

