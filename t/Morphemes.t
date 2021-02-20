#!/usr/bin/env perl
use lib 'lib', '../lib';
use Test::More;
use_ok('XML::Loy');
use_ok('XML::Loy::Example::Morphemes');

ok(my $morph = XML::Loy::Example::Morphemes->new('morph'), 'New morpheme doc');

ok(my $morphemes = $morph->morphemes, 'Morphemes');

ok($morphemes->morpheme, 'Add new morpheme');

is($morph->to_string, '<?xml version="1.0" encoding="UTF-8" standalone="yes"?><morph xmlns="http://www.xstandoff.net/morphemes" xmlns:loy="http://sojolicious.example/ns/xml-loy"><morphemes><morpheme /></morphemes></morph>', 'XML');

done_testing;
