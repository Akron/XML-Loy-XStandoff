#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Warn;
use Data::Dumper;
use File::Temp qw/:POSIX/;
use FindBin;
use lib "$FindBin::Bin/../lib";

use lib (
  't',
  'lib',
  '../lib',
  '../../lib',
  '../../../lib'
);

use_ok('XML::Loy::File');

ok(my $xml = XML::Loy::File->new, 'XML::Loy');


ok($xml = $xml->add('myroot'), 'New root');

ok($xml->add(p => 'My first paragraph'), 'Add Paragraph 1');
ok($xml->add(p => 'My second paragraph'), 'Add Paragraph 2');

my $file_name = tmpnam();

ok($xml->save($file_name), 'Save temporarily');

is($xml->file, $file_name, 'Load file name');

ok(my $xml_2 = XML::Loy::File->new($file_name), 'New document');

is($xml_2->file, $file_name, 'File name correct');

is($xml_2->find('p')->[0]->text, 'My first paragraph', 'First para');

is($xml_2->find('p')->[1]->text, 'My second paragraph', 'Second para');

done_testing;

exit;

1;
