package XML::Loy::AnaWiki::DocumentStructure;
use Data::UUID;
use XML::Loy with => (
  namespace => 'http://www.text-technology.de/anawiki/ds',
  prefix => 'ds'
);

our $UUID = Data::UUID->new;

# Set or get title
sub ds_title {
  my $self = shift;
  return $self->set(title => @_) if $_[0];
  return $self->at('title')->text;
};


# Add or get paragraphs
sub ds_para { shift->_ds(paragraph => @_) };


# Add or get sentences
sub ds_sentence {
  my $self = shift;
  return unless $self->type =~ /^(ds:)?paragraph$/;
  $self->_ds(sentence => @_)
};


# Add or get words
sub ds_word {
  my $self = shift;
  return unless $self->type =~ /^(ds:)?sentence$/;
  $self->_ds(word => @_)
};


# Unify add and get
sub _ds {
  my $self = shift;
  my $tag = shift;

  # Get using selectors
  return $self->at("${tag}[xml\\:id=$_[1]]") if @_ == 2 && $_[0] eq 'id';
  return $self->children($tag)->[($_[1] - 1)] if @_ == 2 && $_[0] eq 'pos';

  # Create attribute hash
  my $attrs = ref $_[0] ? shift : {};
  $attrs->{'xml:id'} //= substr($tag, 0, 1) . '-' . $UUID->create_str;

  # Do not allow text content for paragraphs
  unshift(@_, undef) if $tag eq 'paragraph';

  # Add element
  return $self->add($tag => $attrs, @_);
};


1;


__END__

=pod

=head1 NAME

XML::Loy::AnaWiki::DocumentStructure - Handling AnaWiki Document Structure


=head1 SYNOPSIS

  use XML::Loy::AnaWiki::DocumentStructure;

  my $ds = XML::Loy::AnaWiki::DocumentStructure->new('doc');

  my $p = $ds->ds_para('First Paragraph Comment');
  $p->ds_sentence("That's my first sentence");
  $p->ds_sentence("And my second sentence");
  $p->ds_sentence({ 'xml:id' => 's-3' } => "My final sentence");

  print $p->ds_sentence(pos => 2)->text
  # And my second sentence

  print $xrd->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <doc xmlns="http://www.text-technology.de/anawiki/ds">
  #
  #   <!-- First Paragraph Comment -->
  #   <paragraph xml:id="p-889B5030-...">
  #     <sentence xml:id="s-889BB124-...">That&#39;s my first sentence</sentence>
  #     <sentence xml:id="s-889BD15E-...">And my second sentence</sentence>
  #     <sentence xml:id="s-3">My final sentence</sentence>
  #   </paragraph>
  # </doc>


=head1 DESCRIPTION

L<XML::Loy::AnaWiki::DocumentStructure> is an L<XML::Loy> base class
for dealin with Document Structures as used in the AnaWiki project.

This code may help you to create your own L<XML::Loy> extensions.

B<This module is an early release! There may be significant changes in the future.>

=head1 METHODS

L<XML::Loy::AnaWiki::DocumentStructure> inherits all methods
from L<XML::Loy> and implements the following new ones.


=head2 ds_title

  $doc->ds_title('My Title');
  print $doc->ds_title;

Set or retrieve the title of a document, using L<XML::Loy::set|XML::Loy/set>.

=head2 ds_para

  my $new_para = $doc->ds_para('Comment');
  my $new_para = $doc->ds_para({ xml:id => 'p-2' });

  my $para = $doc->ds_para(pos => 0);
  my $para = $doc->ds_para(id => 'p-2');

Add or retrieve the paragraphs of a document.
Accepts for setting an optional attribute hash and an
optional comment string.
For retrieval accepts a hash pair, getting the paragraph
by position with the C<pos> parameter and by id with the
C<id> parameter.


=head2 ds_sentence

  my $new_s = $p->ds_sentence('Textual Content', 'Comment');
  my $new_s = $p->ds_sentence({ xml:id => 's-2' } => 'my text');

  my $s = $p->ds_sentence(pos => 0);
  my $s = $p->ds_sentence(id => 's-2');
  print $s->text;
  # my text

Add or retrieve the sentences of a paragraph.
Accepts for setting an optional attribute hash, an optional
text content string and an optional comment string.
For retrieval accepts a hash pair, getting the sentence
by position with the C<pos> parameter and by id with the
C<id> parameter.


=head2 ds_word

  my $new_w = $s->ds_word('Elephant');
  my $new_w = $s->ds_word({ xml:id => 'w-2' } => 'Banana');

  my $w = $s->ds_word(pos => 0);
  my $w = $s->ds_word(id => 'w-2');
  print $w->text;
  # Banana

Add or retrieve the words of a sentence.
Accepts for setting an optional attribute hash, an optional
text content string and an optional comment string.
For retrieval accepts a hash pair, getting the word
by position with the C<pos> parameter and by id with the
C<id> parameter.


=head1 DEPENDENCIES

L<Mojolicious>, L<XML::Loy>, L<Data::UUID>.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy-XStandoff


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
