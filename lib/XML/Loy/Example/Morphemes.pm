package XML::Loy::Example::Morphemes;
use XML::Loy with => (
  namespace => 'http://www.xstandoff.net/morphemes',
  prefix    => 'morph'
);

# Add morphemes root
sub morphemes {
  my $self = shift;
  return $self->add(morphemes => @_);
};


# Add morphemes
sub morpheme {
  my $self = shift;
  return unless $self->tag =~ /^(?:morph:)?morphemes$/;
  return $self->add(morpheme => @_);
};

1;
