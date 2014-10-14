#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Warn;

use FindBin;
use lib "$FindBin::Bin/../lib";

use lib '../lib', '../../lib';

use_ok('XML::Loy::Olac');

my $olac = XML::Loy::Olac->new;

$olac->extension(-DublinCore);

# Set dublin core property
ok($olac->dc(title => 'My MetaData document'), 'Set title');

# Get dublin core property
is($olac->dc('title'), 'My MetaData document', 'Get meta data');

# Set with attributes and comments
ok($olac->dc(description => { 'xml:lang' => 'de' } => 'Ein kleines Dokument', 'A Dublin Core Example'), 'Set description');

is($olac->dc('description'), 'Ein kleines Dokument', 'Get description');

# Add dublin core property
ok($olac->dc('+subject' => { 'xsi:type' => 'dcterms:DDC' } => '0.62'), 'Add subject');
ok($olac->dc('+subject' => 'Example'), 'Add subject');

my @subject = $olac->dc('subject');

is($subject[0], '0.62', 'Get subject 1');
is($subject[1], 'Example', 'Get subject 2');

my $author = $olac->dc(author => 'Peter');

is($author->text, 'Peter', 'Author');
is($olac->dc('author'), 'Peter', 'Author');

ok($author->olac_role('annotator'), 'Olac type');
is($author->olac_role, 'annotator', 'Olac type');

# New document - synopsis

$olac = XML::Loy::Olac->new;
$olac->extension(-DublinCore);
$olac->namespace(anno => 'http://myannotation/ns');

$olac->olac_linguistic_field('computational_linguistics');

$olac->add('anno:meta')->dc(author => 'Nils Diewald')->olac_role('annotator');

for ($olac->add('anno:data')->olac_linguistic_type('primary_text')) {
  $_->add('anno:p' => 'My first paragraph');
  $_->add('anno:p' => 'My second paragraph');
};

$olac = XML::Loy::Olac->new;
$olac->extension(-DublinCore);

for ('author') {
  $olac->dc("+$_" => 'Maik Stührenberg')->olac_role($_);
  $olac->dc("+$_" => 'Nils Diewald')->olac_role($_);
};

$olac->dc(title => 'Example');
$olac->dc(description => 'This is an example');

is($olac->at('*')->attr('xmlns:xsi'),
   'http://www.w3.org/2001/XMLSchema-instance',
   'XSI');

is($olac->at('*')->attr('xmlns:olac'),
   'http://www.language-archives.org/OLAC/1.0/',
   'OLAC');

$olac = XML::Loy->new('test');
$olac->extension(-Olac, -DublinCore);

for ('author') {
  $olac->dc("+$_" => 'Maik Stührenberg')->olac_role($_);
  $olac->dc("+$_" => 'Nils Diewald')->olac_role($_);
};

$olac->dc(title => 'Example');
$olac->dc(description => 'This is an example');

is($olac->at('*')->attr('xmlns:xsi'),
   'http://www.w3.org/2001/XMLSchema-instance',
   'XSI');

is($olac->at('*')->attr('xmlns:olac'),
   'http://www.language-archives.org/OLAC/1.0/',
   'OLAC');

done_testing;

__END__



