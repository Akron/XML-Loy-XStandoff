package XML::Loy::DublinCore;
use Carp qw/carp/;
use XML::Loy with => (
  namespace => 'http://purl.org/dc/elements/1.1/',
  prefix    => 'dc'
);

our @CARP_NOT;

# No constructor
sub new {
  carp 'Only use ' . __PACKAGE__ . ' as an extension';
  return;
};


sub dc {
  my $self = shift;
  my $name = lc shift;

  if ($_[0]) {
    if ($name =~ s/^\+\s*//) {
      return $self->add($name => @_);
    }
    else {
      return $self->set($name => @_);
    };
  }

  else {
    my @array = $self->children('dc:' . $name)->pluck('text')->each;
    return $array[0] unless wantarray;
    return @array;
  };
};

1;


__END__


=head2 dc

  # Set dublin core property
  $self->dc(title => 'Object');

  # Get dublin core property
  print $self->dc('title');

  # Set with attributes and comments
  $self->dc(description => {
    'xml:lang' => 'de'
  } => 'Ein kleines Dokument',
  'A Dublin Core Example');

  # Add dublin core property
  $self->dc('+subject' => {
    'xsi:type' => 'dcterms:DDC'
  } => '0.62');


http://dublincore.org/schemas/xmls/qdc/2006/01/06/dc.xsd

title
       creator
       subject
       description
       publisher
       contributor
       date
       type
       format
       identifier
       source
       language
       relation
       coverage
       rights
