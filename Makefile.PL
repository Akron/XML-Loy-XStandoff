#!/usr/bin/env perl
use 5.010001;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME         => 'XML::Loy::XStandoff',
  AUTHOR       => 'Nils Diewald',
  ABSTRACT     => 'Read and Write XStandoff Files',
  VERSION_FROM => 'lib/XML/Loy/XStandoff.pm',
  BUILD_REQUIRES => {
    'Test::More' => 0,
    'Test::Warn' => '0.24'
  },
  PREREQ_PM => {
    'Mojolicious' => '3.93',
    'XML::Loy'    => '0.17',
    'Data::UUID'  => '1.218',
    'Time::Local' => 0,
    'XML::LibXML' => '2'
  },
  LICENSE     => 'perl',
  META_MERGE  => {
    requires  => { perl => '5.010001' },
    resources => {
      license     => 'http://www.opensource.org/licenses/artistic-license-2.0',
      repository  => 'https://github.com/Akron/XML-Loy-XStandoff'
    }
  },
  MIN_PERL_VERSION => '5.010001',
  test => {TESTS => 't/*.t' }
);
