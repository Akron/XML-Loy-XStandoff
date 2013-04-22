#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Mojo::ByteStream 'b';
use File::Temp qw/:POSIX/;
use utf8;

$|++;

my $LIVE = 0;

use FindBin;
use lib "$FindBin::Bin/../lib";

use lib '../lib', '../../lib';

use_ok('XML::Loy::XStandoff');

ok(my $corpus = XML::Loy::XStandoff->new('corpus'), 'New corpus');

ok(my $cd = $corpus->corpus_data(id => 'b5'), 'Add corpusData');

ok(my $pd = $cd->primary_data(id => 'b6'), 'Add primary data');

ok($pd->textual_content('This is my little test suite'), 'Set textual content');

ok($corpus->extension('-XStandoff::Tokenizer'), 'Add extension');

my $level = $cd->add('-Level');

foreach ($cd->tokenize) {
  $level->add('-Word' => { lemma => lc $_->[0] })->seg( $_->[1] );
};


done_testing;

__END__
