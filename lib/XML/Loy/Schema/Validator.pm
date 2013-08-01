package XML::Loy::Schema::Validator;
use XML::LibXML;
use XML::Loy with => (
  on_init   => sub {
    shift->namespace(
      xsi => 'http://www.w3.org/2001/XMLSchema-instance'
    );
  }
);

# Validate the document
sub validate {
  my $self = shift;

  # Get root
  my $root = $self->at(':root');
  my ($schema_loc, $ns) = pop;

  # Get schema location from root
  unless ($schema_loc) {
    ($ns, $schema_loc) = split /\s/, $root->attr('xsi:schemaLocation');
  };

  # Get namespace either by parameter,
  # by schema location or by document namespace
  $ns = shift || $ns || $root->namespace;

  # Create schema object
  my $schema = XML::LibXML::Schema->new( location => $schema_loc );

  # Create document object
  my $doc = XML::LibXML->load_xml(string => $self->to_pretty_xml );

  # Validate schema
  eval { $schema->validate($doc) };

  # Print out warnings and return
  warn $@ and return if $@;

  # Everything is fine - set schemaLocation to document
  $root->attr('xsi:schemaLocation' => "$ns $schema_loc");
  return $self;
};

1;

__END__

=pod

=head1 NAME

XML::Loy::Schema::Validator - Validate Documents using XML Schema


=head1 SYNOPSIS

  use XML::Loy;

  my $doc = XML::Loy->new('doc');
  $doc->extension(-Schema::Validator);
  $doc->add(name => 'Peter' => { 'xml:id' => 'n-1' });

  if ($doc->validate(
        'http://sojolicious/ns/loy',
        'http://sojolicious/ns/loy.xsd'
      )) {
    print "Everything is fine!\n"
  };

=head1 DESCRIPTION

L<XML::Loy::Schema::Validator> is an L<XML::Loy> base class
for validating the document grammar using XML Schema.

This code may help you to create your own L<XML::Loy> extensions.

B<This module is an early release! There may be significant changes in the future.>

=head1 METHODS

L<XML::Loy::Schema::Validator> inherits all methods
from L<XML::Loy> and implements the following new ones.


=head2 validate

  my $doc = $doc->validate(
    'http://sojolicious/ns/loy',
    'http://sojolicious/ns/loy.xsd'
  );

  if (my $doc = $doc->validate('http://sojolicious/ns/loy.xsd')) {
    print $doc->to_pretty_xml;
  };

  print $doc->to_pretty_xml if $doc->validate;

Validate an L<XML::Loy> document with a given schema using L<XML::LibXML>.
Accepts a namespace and the schema location. If the namespace is omitted,
the namespace of the root node is assumed. If the schema location is omitted,
the method searches for a C<xsi:schemaLocation> in the root node.

Returns nothing on failure, otherwise returns the document object.

Errors are printed as warnings.


=head1 DEPENDENCIES

L<Mojolicious>, L<XML::Loy>, L<XML::LibXML>.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy-XStandoff


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
