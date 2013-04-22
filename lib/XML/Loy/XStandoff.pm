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

  unless ($_[1]) {
    return $self->at('primaryData[xml\:id="' . $_[0] . '"]') if $_[0];
    return $self->at('primaryData');
  }
  else {
    my %param = @_;
    $param{'xml:id'} = delete $param{id} if exists $param{id};
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


sub layer {
  my $self = shift;

  $self = $self->at('*') unless $self->type;

  if ($self->type =~ /^(?:xsf:)?(corpus(?:Data)?|level|annotation)?$/) {
    $self = ($self->at('level') or $self->level( id => 'l-' . $UUID->create_str ));
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


sub segment {
  my $self = shift;

  if (@_ == 1) {
    my $id = shift;

    return $self->at('segment[xml\:id=' . $id . ']');
  }

  else {
    my $start = shift;
    my $end   = shift;
    my $id    = shift || 'seg-' . $UUID->create_str;
    if ($self->at("segment[xml\:id=$id]")) {
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


sub seg {
  my $self = shift;
  return $self->attrs('xsf:segment') unless $_[0];

  if (blessed $_[0]) {
    return $self->attrs('xsf:segment' => shift->attrs('xml:id'));
  };

  return $self->attrs('xsf:segment' => shift);
};


sub segment_content {
  my $self = shift;

  my $id;
  if ($self->type =~ /^(xsf:)segment$/) {
    $id = $self->attrs('xml:id');
  }
  else {
    $id = shift;
  };

  my $seg = $self->segmentation->segment($id);

  return unless $seg;

  my $attrs = $seg->attrs;

  my $replace = shift;

  return $self->primary_data->textual_content->string(
    $attrs->{start},
    ($attrs->{end} - $attrs->{start}),
    $replace
  );
};


sub _on_file_change {
  my $self = shift;
  my $data = shift;
  b($data->string)->spurt($data->file);
};

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
    if ($data = $self->at($content)) {
      if ($type eq 'raw') {
	my $data_obj =
	  XML::Loy::XStandoff::Data->new($data->text);
	$data_obj->on(
	  on_change => sub {
	    my $d = shift;
	    $data->replace_content($d->string);
	  }
	);
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
	  $data = XML::Loy::XStandoff::Data->new(
	    b($ref)->slurp
	  );

	  $data->file($ref);

	  $data->on(
	    on_change => sub {
	      $self->_on_file_change(@_)
	    }
	  );
	  $data->on(
	    on_length_change => sub {
	      $self->_on_length_change(@_)
	    }
	  );
	  return $data;
	};

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
    else {
      return $self->set($content);
    };
  };

  # Set data
  my $data;
  if (exists $param{file} || exists $param{uri}) {
    if ($param{file}) {
      $data = b( $param{file} )->slurp;
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

XML::Loy::XStandoff - read and Write XStandoff documents


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


=head2 corpus_data

  $corpus->corpus_data(id => 'cd-1');
  my $cd = $corpus->corpus_data('cd-1');
  my $cd = $corpus->corpus_data;

Get or add corpus data to the corpus.
accepts a parameter hash for setting or a single id parameter for getting.
Giving no parameter will return the first corpus data node.
If no corpus data exists, a new node is introduced with an autogenerated id.

=head2 meta

  $cd->meta->

  $cd->meta(uri => '/meta.xml');
  $cd->meta(uri => 'http://.../meta.xml');
  $cd->meta(as => [-Loy, -DublinCore])->dc('Title');

Set or get meta information of the current node.
Accepts a parameter hash for setting or an

=head2 primary_data

  $cd->primary_data(uri => '/text.txt');
  $cd->primary_data(uri => 'http://.../text.txt');
  $cd->primary_data(file => '/text.txt');
  $cd->primary_data('Hello World');


=head2 textual_content

=head2 segment

  my $id = $cd->segment(4, 5);
  my $id = $cd->segment(4, 5, 'seg-1');

  my $seg = $cd->segment($id);
  print $seg->attrs('start');

=head2 segment_content

  my $content = $cd->segment_content('seg-1');
  my $content = $cd->segment_content('seg-1' => 'war');
  my $content = $cd->segment_content('seg-1' => sub {
    return lc $_[0];
  });

  my $content = $seg->segment_content;
  my $content = $seg->segment_content('war');
  my $content = $seg->segment_content(sub {
    return lc $_[0];
  });


=head2 seg

  # Add attributes to nodes
  $xml->seg('seg-4');
  print $xml->seg;

=head2 annotation

=head2 level

=head2 layer

=head1 DEPENDENCIES

L<XML::Loy>.

=head1 SEE ALSO

L<XML::Loy>, L<XStandoff.net|http://xstandoff.net/>.


=head1 AVAILABILITY

  https://github.com/Akron/XML-Loy-XStandoff


=head1 COPYRIGHT AND LICENSE

Copyright (C) 2013, L<Nils Diewald|http://nils-diewald.de/>.

This program is free software, you can redistribute it
and/or modify it under the same terms as Perl.

=cut
