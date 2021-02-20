package XML::Loy::File;
use Mojo::ByteStream 'b';
use Mojo::File 'path';
use XML::Loy with => (
  prefix    => 'loy',
  namespace => 'http://sojolicious.example/ns/xml-loy'
);


# Constructor
sub new {
  my $class = shift;
  my $file  = shift;

  return $class->SUPER::new unless $file;

  my $data = b(path($file)->slurp)->decode->encode->to_string;

  my $self = $class->SUPER::new($data);
  $self->file($file);
  return $self;
};


# Store filename
sub file {
  my $self = shift;

  # Get root element
  my $root = $self->_root_element or return;

  # Set file name
  if (defined $_[0]) {

    # Get root element
    if ($_[0]) {
      return $root->[2]->{'loy:file'} = shift;
    }

    # Unset file name
    else {
      return delete $root->[2]->{'loy:file'};
    };
  };

  # Get file name
  return $root->[2]->{'loy:file'};
};


# Save document to filesystem
sub save {
  my $self = shift;

  # Get file name
  my $file = shift || $self->file || return;

  # Remember filename
  $self->file($file) unless $self->file;

  # Save data to filesystem
  return path($file)->spurt($self->root->to_pretty_xml);
};


# Load document from filesystem
sub load {
  my $self = shift;

  # Get file name
  my $file = shift || $self->file || return;

  # Load data from file
  my $byte = Mojo::ByteStream->new($file)->slurp or return;

  # Remember filename
  $self->file($file);

  # Create new document
  return $self->new($byte);
};


# Delete file
sub delete {
  my $self = shift;

  # Get file name
  my $file = shift || $self->file || return;

  if (unlink $file) {
    $self->file('');
    return 1;
  };

  return;
};


1;


__END__

=pod

Not ready yet
