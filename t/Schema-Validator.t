#!/usr/bin/env perl
use lib '../lib', 'lib';
use Test::More tests => 25;
use Test::Warn;

use_ok('XML::Loy::XStandoff');

ok(my $corpus = XML::Loy::XStandoff->new('corpus'), 'Create Corpus');
ok(my $doc = $corpus->textual_content('Give me the hammer!'), 'Create Textual Content');

ok($corpus->segmentation, 'Create Segmentation');
ok(my $data = $corpus->layer->extension('-AnaWiki::DocumentStructure'), 'Create doc structure');

ok(my $sentence = $data->ds_para->ds_sentence, 'Add sentence');

ok($corpus->extension('-XStandoff::Tokenizer'), 'Add tokenizer extension');

foreach ($doc->tokenize) {
  ok($sentence->ds_word({surface => $_->[0]})->seg($_->[1]), 'Add word');
};

is($corpus->at(':root')->attr('xmlns:ds'), 'http://www.text-technology.de/anawiki/ds', 'ds ns');

is($corpus->at(':root')->attr('xmlns:xsf'), 'http://www.xstandoff.net/2009/xstandoff/1.1', 'xsf ns');

is($corpus->primary_data->attr('end'), 19, 'End of textual data');
is($corpus->primary_data->attr('start'), 0, 'Start of textual data');

ok(my $s = $corpus->level->layer->ds_para(pos => 0)->ds_sentence(pos => 0), 'First sentence');

foreach my $w ($s->children('word')->each) {
  is($w->attr('surface'), $w->segment_content,
     'Word matches');
};

my $loc = 'http://www.xstandoff.net/2009/xstandoff/1.1/xsf.xsd';

ok(my $c = $corpus->extension('-Schema::Validator')->validate($loc), 'Validate');

ok($c = $c->validate, 'Validate');
ok($c->add('Funny'), 'Add problem');

warning_like {
  $c->validate
} qr{Schemas validity error}, 'Validate failure';

warning_like {
  $c->validate
} qr{Element '\{http\:\/\/www\.xstandoff\.net\/2009\/xstandoff\/1\.1\}Funny'}, 'Validate failure';


__END__
