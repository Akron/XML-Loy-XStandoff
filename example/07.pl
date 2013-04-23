#!/usr/bin/env perl
use lib 'lib', '../lib';

use XML::Loy::XStandoff;

my $corpus = XML::Loy::XStandoff->new('corpus');
my $doc = $corpus->textual_content('Give me the hammer!');
$corpus->segmentation;
my $data = $corpus->layer->extension('-AnaWiki::DocumentStructure');
my $s = $data->ds_para->ds_sentence;

foreach ($doc->extension('-XStandoff::Tokenizer')->tokenize) {
  $s->ds_word({lemma => lc $_->[0]})->seg($_->[1]);
};

# use extension
$corpus->extension('-Schema::Validator');

# XML Schema location
my $loc = 'http://www.xstandoff.net/2009/xstandoff/1.1/xsf.xsd';

print 'The instance is ';
print $corpus->validate($loc) ? 'valid' : 'invalid';

$corpus->segmentation->add('wrongElement');

print 'The instance is ';
print $corpus->validate($loc) ? 'valid' : 'invalid';

