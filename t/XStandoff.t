#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Mojo::ByteStream 'b';
use File::Temp qw/:POSIX/;
use utf8;

my $LIVE = 0;

use FindBin;
use lib "$FindBin::Bin/../lib";

use lib '../lib', '../../lib';

use_ok('XML::Loy::XStandoff');

ok(my $corpus = XML::Loy::XStandoff->new('corpus'), 'New corpus');

ok(my $cd = $corpus->corpus_data(id => 'b5'), 'Add corpusData');

ok(my $meta = $cd->meta, 'Add meta');

ok($meta->add('dc:title' => 'My title'), 'Add Meta information');

is($meta->at('dc\:title')->text, 'My title', 'Get Meta information');

ok($cd->meta(uri => 'http://.../'), 'Add Meta reference');

ok($cd->meta(uri => $FindBin::Bin . '/files/meta.xml'), 'Add Meta reference');

ok(my $desc = $cd->meta->at('Description'), 'Description');

is($desc->at('creator')->text, 'Karl Mustermann', 'Creator');

ok($meta = $cd->meta(as => [-Loy, -DublinCore]), 'Meta');

ok($desc = $meta->at('Description'), 'Description');

is($desc->dc('creator'), 'Karl Mustermann', 'Creator');
is($desc->dc('title'), 'Algebra', 'Title');
is($desc->dc('subject'), 'mathematics', 'Subject');
is($desc->dc('date'), '2000-01-23', 'Date');
is($desc->dc('language'), 'EN', 'Language');
is($desc->dc('description'), 'An introduction to algebra', 'Description');

ok(my $pd = $cd->primary_data(id => '6', hallo => 'test'), 'Add primary data');

ok($pd->textual_content('Mein Text'), 'Set textual content');

ok($pd->textual_content(file => $FindBin::Bin . '/files/text.txt'),
   'Set textual content');

is($pd->textual_content, "Dies ist mein Text.", 'Get textual data');

ok($pd->textual_content(uri => $FindBin::Bin . '/files/text.txt'),
   'Set textual content');

is($pd->textual_content, "Dies ist mein Text.\n", 'Get textual data');

if ($LIVE) {

  ok($pd->textual_content(uri => 'http://www.spiegel.de/robots.txt'),
     'Set textual content');

  like($pd->textual_content, qr{User-agent}, 'Get textual data');
};

ok(!$pd->at('textualContent'), 'No element for textual content');

ok($pd->textual_content("Dies ist mein Text.\n"),
   'Set textual content');

ok(my $segs = $cd->segmentation, 'Add segmentation');

ok(my $id1 = $segs->segment(0, 4), 'Segment');

is($segs->segment($id1)->attr('start'), 0, 'Segment');
is($segs->segment($id1)->attr('end'), 4, 'Segment');

ok(my $id2 = $segs->segment(5, 8), 'Segment');

is($segs->segment($id2)->attr('start'), 5, 'Segment');
is($segs->segment($id2)->attr('end'), 8, 'Segment');


ok(my $id3 = $segs->segment(9, 13), 'Segment');

is($segs->segment($id3)->attr('start'), 9, 'Segment');
is($segs->segment($id3)->attr('end'), 13, 'Segment');

is($segs->segment($id1)->segment_content, 'Dies', 'Correct substring');
is($segs->segment($id2)->segment_content, 'ist', 'Correct substring');
is($segs->segment($id3)->segment_content, 'mein', 'Correct substring');


ok(my $id4 = $segs->segment(14, 18), 'Segment');

is($segs->segment($id4)->segment_content, 'Text', 'Correct substring');

ok(my $id5 = $segs->segment(0, 19), 'All Segment');

is($segs->segment($id5)->segment_content, 'Dies ist mein Text.',
   'Correct substring');

is($segs->segment($id2)->segment_content(
  sub {
    return uc shift();
  }), 'IST', 'Correct substring');

is($pd->textual_content, 'Dies IST mein Text.', 'Get textual content');

is($segs->segment($id2)->segment_content(
  sub {
    return 'wäre';
  }), 'wäre', 'Correct substring');

is($segs->segment($id3)->segment_content, 'mein', 'Correct substring');

is($segs->segment($id3)->attr('start'), 10, 'Segment');
is($segs->segment($id3)->attr('end'), 14, 'Segment');


is($segs->segment($id3)->attr('start'), 10, 'Segment');
is($segs->segment($id3)->attr('end'), 14, 'Segment');

is($segs->segment($id5)->segment_content, 'Dies wäre mein Text.',
   'Correct substring');


my $data = b($FindBin::Bin . '/files/text.txt')->slurp;

my $file_name = tmpnam();

ok(b($pd->textual_content)->spurt($file_name), 'Save file');

ok($pd->textual_content(uri => $file_name), 'Set textual content');

is($pd->at('primaryDataRef')->attr('uri'), $file_name, 'PrimaryDataRef');

ok($pd->textual_content(file => $file_name), 'Set textual content');


is($segs->segment($id1)->attr('start'), 0, 'Segment');
is($segs->segment($id1)->attr('end'), 4, 'Segment');

ok($cd->textual_content, 'Textual Content is set');

is($cd->segment($id1)->segment_content, 'Dies', 'Correct substring');
is($cd->segment($id2)->segment_content, 'wäre', 'Correct substring');
is($cd->segment($id3)->segment_content, 'mein', 'Correct substring');
is($cd->segment($id4)->segment_content, 'Text', 'Correct substring');

# Change on disk
ok($pd->segment($id1)->segment_content('Das'), 'Change on disk');

is($cd->segment($id1)->segment_content, 'Das', 'Correct substring');
is($cd->segment($id2)->segment_content, 'wäre', 'Correct substring');
is($cd->segment($id3)->segment_content, 'mein', 'Correct substring');
is($cd->segment($id4)->segment_content, 'Text', 'Correct substring');

is($pd->textual_content, 'Das wäre mein Text.', 'Disk data');


# diag $corpus->to_pretty_xml;


done_testing;

__END__



# diag $corpus->to_pretty_xml;



