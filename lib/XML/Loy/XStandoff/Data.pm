package XML::Loy::XStandoff::Data;
use Mojo::Base -strict;
use Scalar::Util qw/weaken/;

use Carp qw/carp/;
our @CARP_NOT;

use overload '""' => sub { shift->string }, fallback => 1;

sub new {
  my $class = shift;
  my $self = bless {
    on_change => sub {},
    on_length_change => sub {},
  }, $class;

  $self->data( shift );

  $self->{unchangeable} = shift;

  return $self;
};


sub file {
  my $self = shift;
  if ($_[0]) {
    return $self->{file} = shift;
  };
  return $self->{file};
};

sub unchangeable {
  return shift->{unchangeable} // 0;
};


sub on {
  my $self = shift;
  my $name = shift;
  $self->{$name} = shift;
};


sub data {
  my $self = shift;
  if ($_[0]) {
    my $new = $_[0];
    return ($self->{data} = \$new);
  }
  else {
    return $self->{data} // \'';
  };
};


sub string {
  my $self = shift;

  my $start = shift;
  my $length = shift;
  my $replace = shift;

  unless ($length) {
    return ${$self->data};
  };

  unless ($replace) {
    my $s = ${ $self->data };
    my $rv = substr( $s, $start, $length);
    $self->data($s);
    return $rv;
  };

  if ($self->unchangeable) {
    carp 'You cannot change this data' and return;
  };

  my ($old, $new);

  my $s = ${ $self->data };
  if (ref $replace && ref $replace eq 'CODE') {
    $old = substr( $s, $start, $length);
    $new = $replace->( $old );
    substr( $s, $start, $length, $new);
  } else {
    $old = substr($s, $start, $length, $replace);
    $new = $replace;
  };
  $self->data($s);


  if ((length($old) - length($new)) != 0) {
    my $copy = $self;
    weaken $copy;
    $self->{on_length_change}->(
      $copy,
      $start,
      ($start + $length),
      $old,
      $new
    );
  };

  if ($old ne $new) {
    my $copy = $self;
    weaken $copy;
    $self->{on_change}->(
      $copy,
      $start,
      ($start + $length),
      $old,
      $new
    );
  };

  return $new;
};


1;


__END__

my $data = XML::Loy::XStandoff::Data->new;

on_data_change
on_length_change
