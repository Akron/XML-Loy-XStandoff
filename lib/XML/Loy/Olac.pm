package XML::Loy::Olac;
use Mojo::Util;
use Carp qw/carp/;

our @CARP_NOT;

our $VERSION = '0.1';

use XML::Loy with => (
  namespace => 'http://www.language-archives.org/OLAC/1.0/',
  prefix    => 'olac',
  on_init => sub {
    my $self = shift;
    $self->namespace(xsi  => 'http://www.w3.org/2001/XMLSchema-instance');
    $self->namespace(olac => 'http://www.language-archives.org/OLAC/1.0/');
  }
);

sub new {
  my $class = shift;
  return $class->SUPER::new(scalar @_ ? @_ : 'olac');
};

# Create olac atribute seter and getter
foreach my $name (qw/role
		     discourse_type
		     linguistic_type
		     linguistic_field
		     language/) {

  my $olac_name = "olac:$name";
  $olac_name =~ tr/_/-/;

  # Add methods to class
  Mojo::Util::monkey_patch __PACKAGE__, 'olac_' . $name, sub {
    my $self = shift;

    $self = $self->at('*') unless $self->parent;

    if (@_ == 1) {
      $self->attrs('xsi:type'  => $olac_name);
      $self->attrs('olac:code' => lc shift);
    }

    elsif ($self->attrs('xsi:type') eq $olac_name) {
      return $self->attrs('olac:code');
    };

    return $self;
  };
};


1;


__END__

=pod

=head2 new

  my $olac = XML::Loy::Olac->new(-DublinCore);
  $olac->namespace(anno => 'http://myannotation/ns');

  $olac->olac_linguistic_field('computational_linguistics');

  $olac->add('anno:meta')->dc(author => 'Nils Diewald')->olac_role('annotator');

  for ($olac->add('anno:data')->olac_linguistic_type('primary_text')) {
    $_->add('anno:p' => 'My first paragraph');
    $_->add('anno:p' => 'My second paragraph');
  };

  print $olac->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <olac olac:code="computational_linguistics"
  #       xmlns="http://www.language-archives.org/OLAC/1.0/"
  #       xmlns:anno="http://myannotation/ns"
  #       xmlns:dc="http://purl.org/dc/elements/1.1/"
  #       xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
  #       xsi:type="olac-linguistic-field">
  #   <anno:meta>
  #     <dc:author olac:code="annotator"
  #                xsi:type="olac-role">Nils Diewald</dc:author>
  #   </anno:meta>
  #   <anno:data olac:code="primary_text"
  #              xsi:type="olac-linguistic-type">
  #     <anno:p>My first paragraph</anno:p>
  #     <anno:p>My second paragraph</anno:p>
  #   </anno:data>
  # </olac>


=head2 olac_discourse_type

  $dom->olac_discourse_type('drama');
  say $dom->olac_discourse_type;

  dialogue
  drama
  formulaic
  ludic
  arotory
  narrative
  procedural
  report
  singing
  unintelligible_speech

=head2 olac_linguistic_type

  $dom->olac_linguistic_type('primary_text');
  say $dom->olac_linguistic_type;

  language_description
  lexicon
  primary_text

=head2 olac_linguistic_field

  $dom->olac_linguistic_field('applied_linguistics');
  say $dom->olac_linguistic_field;

  anthropological_linguistics
  applied_linguistics
  cognitive_science
  computational_linguistics
  discourse_analysis
  forensic_linguistics
  general_linguistics
  historical_linguistics
  history_of_linguistics
  language_acquisition
  language_documentation
  lexicography
  linguistics_and_literature
  linguistic_theories
  mathematical_linguistics
  morphology
  neurolinguistics
  philosophy_of_language
  phonetics
  phonology
  pragmatics
  psycholinguistics
  semantics
  sociolinguistics
  syntax
  text_and_corpus_linguistics
  translating_and_interpreting
  typology
  writing_systems

=head2 olac_language

  $dom->olac_language('de');
  say $dom->olac_language;

=head2 olac_language

  $dom->olac_role('annotator');
  say $dom->olac_annotator;

  annotator
  author
  compiler
  consultant
  data_inputter
  depositor
  developer
  editor
  illustrator
  interpreter
  interviewer
  participant
  performer
  photographer
  recorder
  researcher
  research_participant
  responder
  signer
  singer
  speaker
  sponsor
  transcriber
  translator
