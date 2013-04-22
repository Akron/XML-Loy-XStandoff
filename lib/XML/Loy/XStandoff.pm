package XML::Loy::XStandoff;
use XML::Loy with => (
  mime      => 'application/prs.xsf+xml',
  namespace => 'http://www.xstandoff.net/2009/xstandoff/1.1',
  prefix    => 'xsf',
  on_init   => sub {
    shift->namespace(
      xsf => 'http://www.xstandoff.net/2009/xstandoff/1.1'
    );
  }
);

our $VERSION = '0.2';

use XML::Loy::XStandoff::Data;
use XML::Loy::File;
use Mojo::ByteStream 'b';
use Mojo::UserAgent;
use Carp qw/carp/;
use Data::UUID;
use Scalar::Util qw/blessed/;

# Todo:
# - use XML::Loy::Date::RFC3339;
# - iso-8601
# - mimeType => '...'

our $UUID;
BEGIN { $UUID = Data::UUID->new };

our @CARP_NOT;

# Add or get corpus data
sub corpus_data {
  my $self = shift;

  # Get first element if no type defined
  $self = $self->at('*') unless $self->type;

  # Get corpus data
  unless ($_[1]) {
    return $self->at('corpusData[xml\:id="' . $_[0] . '"]') unless $_[0];
    return $self->at('corpusData');
  };

  # Set corpus data
  my %param = @_;
  $param{'xml:id'} = delete $param{id} if exists $param{id};
  return $self->add(corpusData => \%param);
};


# Set or return meta data
sub meta {
  return shift->_ref_type(qw/meta metaRef as/, @_);
};


# Add or return primary data
sub primary_data {
  my $self = shift;

  # Get first node if not there
  $self = $self->at('*') unless $self->type;

  if ($self->type =~ /^(?:xsf:)?corpus$/) {
    $self = (
      $self->at('corpusData') ||
	$self->corpus_data( id => 'cd-' . $UUID->create_str )
      );
  };

  # Climb up the tree
  while ($self->type !~ /^(?:xsf:)?corpusData$/) {
    $self = $self->parent or return;
  };

  # Get primary data
  unless ($_[1]) {
    return $self->at('primaryData[xml\:id="' . $_[0] . '"]') if $_[0];
    return $self->at('primaryData');
  }
  else {
    my %param = @_;
    $param{'xml:id'} //= delete $param{id} if exists $param{id};
    return $self->add(primaryData => \%param);
  };
};


# textualContent + PrimaryDataRef
sub textual_content {
  my $self = shift;

  $self = $self->at('*') unless $self->type;

  if ($self->type =~ /^(?:xsf:)?corpus(?:Data)?$/) {
    $self = ($self->at('primaryData') or $self->primary_data( id => 'pd-' . $UUID->create_str ));
  }
  else {
    while ($self->type !~ /^(?:xsf:)?primaryData$/) {
      $self = $self->parent or return;
    };
  };

  my $tc = $self->_ref_type(qw/textualContent primaryDataRef raw/, @_);
  my $pd = $self->primary_data;
  $pd->attrs(start => 0);
  $pd->attrs(end => length($tc));
  return $tc;
};


# Create segmentation element
sub segmentation {
  my $self = shift;

  $self = $self->at('*') unless $self->type;

  if ($self->type =~ /^(?:xsf:)?corpus$/) {
    $self = ($self->at('corpusData') or $self->corpus_data( id => 'cd-' . $UUID->create_str ));
  }
  else {
    while ($self->type !~ /^(?:xsf:)?corpusData$/) {
      $self = $self->parent or return;
    };
  };

  return ($self->at('segmentation') or $self->set(segmentation => @_));
};


# Create or retrieve an annotation element
sub annotation {
  my $self = shift;

  $self = $self->at('*') unless $self->type;

  if ($self->type =~ /^(?:xsf:)?corpus$/) {
    $self = ($self->at('corpusData') or $self->corpus_data( id => 'cd-' . $UUID->create_str ));
  }
  else {
    while ($self->type !~ /^(?:xsf:)?corpusData$/) {
      $self = $self->parent or return;
    };
  };

  return ($self->at('annotation') or $self->set(annotation => @_));
};

# Create or retrieve a level element
sub level {
  my $self = shift;

  $self = $self->at('*') unless $self->type;

  if ($self->type =~ /^(?:xsf:)?corpus(?:Data)?$/) {
    $self = $self->annotation;
  };

  while ($self->type !~ /^(?:xsf:)?annotation$/) {
    $self = $self->parent or return;
  };

  unless ($_[1]) {
    return $self->at('level[xml\:id="' . $_[0] . '"]') if $_[0];
    return $self->at('level');
  }
  else {
    my %param = @_;
    $param{'xml:id'} = delete $param{id} if exists $param{id};
    return $self->add(level => \%param);
  };
};


# Create or retrieve a layer element
sub layer {
  my $self = shift;

  $self = $self->at('*') unless $self->type;

  if ($self->type =~ /^(?:xsf:)?(corpus(?:Data)?|level|annotation)?$/) {
    $self = ($self->at('level') or $self->level( id => 'lev-' . $UUID->create_str ));
  }
  else {
    while ($self->type !~ /^(?:xsf:)?level$/) {
      $self = $self->parent or return;
    };
  };

  my %param = @_;
  $param{priority} = 0 unless defined $param{priority};

  return ($self->at('layer') or $self->set(layer => @_));
};


# Add or retrieve segment elements
sub segment {
  my $self = shift;

  # Retrieve segment
  if (@_ == 1) {
    my $id = shift;

    unless ($self->type =~ /^(?:xsf:)?segmentation/) {
      while ($self->type !~ /^(?:xsf:)?corpusData$/) {
	$self = $self->parent or return;
      };
    };

    return $self->at('segment[xml\:id=' . $id . ']');
  }

  # Add or modify segment
  else {
    my $end   = pop;
    my $start = pop;
    my $id    = shift || 'seg-' . $UUID->create_str;
    if (my $seg = $self->at("segment[xml\:id=$id]")) {
      $seg->attrs(start => $start);
      $seg->attrs(end => $end);
      return $id;
    }
    else {
      my $segs = $self->segmentation;

      if ($segs->add(segment => {
	'xml:id' => $id,
	'start'  => $start,
	'end'    => $end,
	'type'   => 'char'
      })) {
	return $id;
      };
    };
  };
  return;
};


# Add or get segment attribute to element
sub seg {
  my $self = shift;
  return $self->attrs('xsf:segment') unless $_[0];

  if (blessed $_[0]) {
    return $self->attrs('xsf:segment' => shift->attrs('xml:id'));
  };

  return $self->attrs('xsf:segment' => shift);
};


# Retrieve, replace or modify segment content
sub segment_content {
  my $self = shift;
  my $replace = shift;

  my ($id, $seg);
  if ($self->type =~ /^(?:xsf:)?segment$/) {
    $seg = $self;
  }
  else {
    $id = $self->seg;
    $seg = $self->segmentation->segment($id);
  };

  return unless $seg;

  my $attrs = $seg->attrs;

  return $self->primary_data->textual_content->string(
    $attrs->{start},
    ($attrs->{end} - $attrs->{start}),
    $replace
  );
};


# Autosave primary data on change
sub _on_file_change {
  my $self = shift;
  my $data = shift;
  b($data->string)->spurt($data->file);
};


# Change segment range in case the primary data is changed
sub _on_length_change {
  my $self = shift;
  my $data = shift;
  my ($start, $end, $old, $new) = @_;

  my $diff = length($new) - length($old);

  $self->segmentation->children('segment')->each(
    sub {
      my $seg = shift;
      my $attrs = $seg->attrs;

      if ($attrs->{start} >= $end) {
	$attrs->{start} += $diff
      };
      if ($attrs->{end} >= $end) {
	$attrs->{end} += $diff
      };
    }
  );

  my $pd = $self->primary_data;
  my $tc = $pd->textual_content;
  $pd->attrs(start => 0);
  $pd->attrs(end => length $tc);
};


# External or internal reference type for meta and textual content
sub _ref_type {
  my $self = shift;

  my $content = shift;
  my $content_ref = shift;
  my $type = shift;

  my (%param, $set);

  if ((@_ % 2) == 0) {
    %param = @_;
  }

  elsif (@_ == 1) {
    $set = 1;
  };

  # Get data
  if ((keys(%param) == 0 && !$set)  || $param{as}) {
    my @as = $param{as} ? (ref($param{as}) ? @{$param{as}} : $param{as}) : ();

    my ($data, $rv);

    # node is found
    if ($data = $self->at($content)) {

      # Return raw
      if ($type eq 'raw') {
	my $data_obj =
	  XML::Loy::XStandoff::Data->new($data->text);

	# On change, replace the content
	$data_obj->on(
	  on_change => sub {
	    my $d = shift;
	    $data->replace_content($d->string);
	  }
	);

	# On length change, update primary data segments
	$data_obj->on(
	  on_length_change => sub {
	    $self->_on_length_change(@_)
	  }
	);
	return $data_obj;
      };
      return $data;
    }

    # Is reference
    elsif ($data = $self->at($content_ref)) {
      my $ref = $data->attrs('uri');

      # Is local
      if ($ref =~ s!^file://!! or $ref !~ /^[a-zA-Z]+:/) {

	if ($type eq 'raw') {

	  # Load file
	  $data = XML::Loy::XStandoff::Data->new(
	    b($ref)->slurp
	  );

	  # Set file information
	  $data->file($ref);

	  # On change, replace the content
	  $data->on(
	    on_change => sub {
	      $self->_on_file_change(@_)
	    }
	  );

	  # On length change, update primary data
	  $data->on(
	    on_length_change => sub {
	      $self->_on_length_change(@_)
	    }
	  );
	  return $data;
	};

	# Load as XML::Loy document
	my $xml = XML::Loy::File->new($ref);
	$xml = $xml->as(@as, -File) if @as;
	return $xml;
      }

      # Is on the web
      else {
	my $tx = Mojo::UserAgent->new->get($ref);
	my $res = $tx->success || return '';

	my $data = $res->body;

	if ($type eq 'raw') {
	  return XML::Loy::XStandoff::Data->new($data->text, 1);
	};

	return XML::Loy->new($data)->as(@as);
      };
    }

    # Create node
    else {
      if ($type eq 'raw') {
	my $data_obj =
	  XML::Loy::XStandoff::Data->new;

	# On change, replace the content
	$data_obj->on(
	  on_change => sub {
	    my $d = shift;
	    $data->replace_content($d->string);
	  }
	);

	# On length change, update primary data segments
	$data_obj->on(
	  on_length_change => sub {
	    $self->_on_length_change(@_)
	  }
	);
	return $data_obj;
      };

      return $self->set($content);
    };
  };

  # Set data
  my $data;
  if (exists $param{file} || exists $param{uri}) {
    if ($param{file}) {
      $data = b( $param{file} )->slurp;
      # Is a document
      if ($type ne 'raw') {
	$self->find($content_ref)->pluck('remove');
	return $self->set($content)->add( $self->new($data) );
      };
    }
    elsif ($param{'uri'}) {
      $self->find($content)->pluck('remove');

      return $self->set($content_ref => { uri => $param{uri} });
    };
  }
  else {
    $data = shift;
  };

  $self->find($content_ref)->pluck('remove');
  return $self->set($content => {} => $data);
};


1;


__END__

=pod

=head1 NAME

XML::Loy::XStandoff - Read and Write XStandoff Documents


=head1 SYNOPSIS

  use XML::Loy::XStandoff;

  # Create new corpus element
  my $xsf = XML::Loy::XStandoff->new('corpus');

  # Create new corpusData element
  my $cd = $xsf->corpus_data(id => 'cs_1');

  # Add meta information
  $cd->meta->add('dc:title' => 'My Document');

  # Set textual content
  $cd->textual_content('My text');

  # Create segment spans
  $cd->segment(0, 2);
  my $seg = $cd->segment(3, 7);

  # Return textual content based on segment spans
  print $xsf->segment_content($seg);
  # text

  # Modify primary data
  $xsf->segment_content(
    $seg => sub {
      uc $_[0];
    });

  # Return XStandoff document
  print $xsf->to_pretty_xml;

  # <?xml version="1.0" encoding="UTF-8" standalone="yes"?>
  # <corpus xmlns="http://www.xstandoff.net/2009/xstandoff/1.1"
  #         xmlns:xsf="http://www.xstandoff.net/2009/xstandoff/1.1">
  #   <corpusData xml:id="cs_1">
  #     <meta>
  #       <dc:title>My Document</dc:title>
  #     </meta>
  #     <primaryData end="7" start="0" xml:id="pd-F82533A0-...">
  #       <textualContent>My TEXT</textualContent>
  #     </primaryData>
  #     <segmentation>
  #       <segment end="2" start="0" type="char" xml:id="seg-F825B7DA-..." />
  #       <segment end="7" start="3" type="char" xml:id="seg-F82617FC-..." />
  #     </segmentation>
  #   </corpusData>
  # </corpus>

=head1 DESCRIPTION

L<XML::Loy::XStandoff> is an L<XML::Loy> class
for dealing with L<XStandoff|http://xstandoff.net/> documents.

This code may help you to create your own L<XML::Loy> extensions.

B<This module is an early release! There may be significant changes in the future.>


=head1 METHODS

L<XML::Loy::XStandoff> inherits all methods
from L<XML::Loy> and implements the following new ones.


=head2 new

  my $corpus = XML::Loy::XStandoff->new('corpus');
  my $cd = XML::Loy::XStandoff->new('corpusData');

Create a new L<XML::Loy::XStandoff> document, either as
a C<corpus> or a C<corpusData> element.


=head2 annotation

  my $anno = $cd->annotation;

  $cd->annotation->add('level');

Retrieve an C<annotation> element and set it, if it doesn't exist
(along with a C<corpusData> element.


=head2 corpus_data

  $corpus->corpus_data(id => 'cd-1');
  my $cd = $corpus->corpus_data('cd-1');
  my $cd = $corpus->corpus_data;

Get or add corpus data to the corpus.
accepts a parameter hash for setting or a single id parameter for getting.
Giving no parameter will return the first corpus data node.
If no corpus data exists, a new node is introduced with an autogenerated id.


=head2 layer

  my $lay = $a->layer('xml:id' => 'lay-1');
  my $lay = $a->layer('lay-1');
  my $lay = $a->layer;

Add an annotation layer to the annotation level or retrieve it.

Accepts a hash of attributes for adding a new C<layer>
element.

For retrieval it accepts an id value. If no value is passed, the first
element in document order is returned. In case no C<layer> element
exists, it is created (along with a C<level>, an C<annotation>, and a
C<corpusData> element).


=head2 level

  my $lev = $a->level('xml:id' => 'lev-1');
  my $lev = $a->level('lev-1');
  my $lev = $a->level;

Add an annotation level to the annotation or retrieve it.

Accepts a hash of attributes for adding a new C<level>
element.

For retrieval it accepts an id value. If no value is passed, the first
element in document order is returned. In case no C<level> element
exists, it is created (along with an C<annotation> and a C<corpusData>
element).


=head2 meta

  my $meta = $cd->meta;

  $cd->meta->add('dc:title' => 'My title');

  $cd->meta(uri  => '/meta.xml');
  $cd->meta(file => '/meta.xml');
  $cd->meta(uri  => 'http://.../meta.xml');
  $cd->meta(as   => [-Loy, -DublinCore])->dc('Title');

Set meta information of the current node or retrieve it.

If no parameter is given, the content of the C<meta> element is returned.
If no C<meta> element exists, but a C<metaRef> element exists,
the referenced document is returned (either from a local file or an URI).
If a parameter C<as> is given,
the passed array reference is used to transform the document
using the L<as|XML::Loy/as> method of L<XML::Loy>.
If no meta document is associated to the node, it is created empty.

If a C<file> parameter is passed, the content of the document is embedded
as a child of the meta element. If a C<uri> parameter is passed, a
C<metaRef> node is created.

B<Note>: External meta documents will be extended with L<XML::Loy::File>
and thus have to be stored separately when changed.


=head2 primary_data

  my $pd = $cd->primary_data('xml:id' => 'pd-1');
  my $pd = $cd->primary_data('pd-1');
  my $pd = $cd->primary_data;

Add primary data to corpus data or retrieve it.

Accepts a hash of attributes for adding a new C<primaryData>
element.

For retrieval it accepts an id value. If no value is passed, the first
element in document order is returned. In case no C<primaryData> element
exists, it is created (along with a C<corpusData> element).


=head2 segment_content

  print $lay->at('token')->segment_content;
  print $cd->segment('seg-1')->segment_content;

  $lay->at('token')->segment_content('new');
  $lay->at('token')->segment_content(sub {
    return lc $_[0];
  });

Retrieve, replace or modify the content of a specific segment.
If invoked by a C<segment> node, takes this segment, otherwise
takes the C<xsf:segment> attribute value of the invoking node.

If no parameter is given, returns the textual content of the segment.
Accepts a string parameter, that replaces the textual content of the
segment.
Accepts a callback method, that accepts the textual content of
the segment and returns a string to replace the textual content.

On change, the primary data (either embedded or on a local filesystem)
and segments are updated.


=head2 segmentation

  my $seg = $cd->segmentation;

  $cd->segmentation->add('segment');

Retrieve a C<segmentation> element and set it, if it doesn't exist
(along with a C<corpusData> element.


=head2 segment

  my $seg = $cd->segment('seg-1');
  print $seg->attrs('start');

  my $seg_id = $cd->segment(14, 20);
  my $seg_id = $cd->segment(14, 20);
  $cd->segment('seg-1', 14, 21);

Add or retrieve segments.

Accepts a segment id for retrieving a segment.
Accepts two integers for defining start and end position of the segment.
Accepts a segment id, followed by two integers for
modifying start and end position of the segment.


=head2 seg

  $lay->add('token')->seg('seg-1');
  # <token xsf:segment="seg-1" />

  print $lay->at('token')->seg;
  # seg-1

Attach segment information to arbitrary elements or retrieve it.


=head2 textual_content

  $pd->textual_content(uri => '/text.txt');
  $pd->textual_content(uri => 'http://.../text.txt');
  $pd->textual_content(file => '/text.txt');
  $pd->textual_content('Hello World');

  print $pd->textual_content;

Add textual data to corpus data or retrieve it.

If no parameter is given, the content of the C<textualContent>
element is returned as an L<XML::Loy::XStandoff::Data> object.
If no C<textualContent> element exists, but a C<primaryDataRef> element exists,
the referenced document is returned (either from a local file or an URI).
If no textual content is associated to the primary data, it is created empty
and returned as an L<XML::Loy::XStandoff::Data> object.

If a C<file> parameter is passed, the content of the file
is embedded as the content of the C<textualContent> element.
If a C<uri> parameter is passed, a C<primaryDataRef> node is created.

B<Note>: External textual content files referenced by a URI cannot be
altered using L<segment_content|/segment_content>.


=head1 DEPENDENCIES

L<XML::Loy>.

=head1 SEE ALSO

L<XML::Loy>,
L<XML::Loy::XStandoff::Data>,
L<XML::Loy::File>,
L<XStandoff.net|http://xstandoff.net/>.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy-XStandoff


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
