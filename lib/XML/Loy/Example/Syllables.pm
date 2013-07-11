package XML::Loy::Example::Syllables;
use XML::Loy with => (
  namespace => 'http://www.xstandoff.net/syllables',
  prefix    => 'syll'
);

# Add morphemes root
sub syllables {
  my $self = shift;
  return $self->add(syllables => @_);
};


# Add morphemes
sub syllable {
  my $self = shift;
  return unless $self->type =~ /^(?:syll:)?syllables$/;
  return $self->add(syllable => @_);
};

1;
