package XML::Loy::XStandoff::Tokenizer;
use XML::Loy -base;
use utf8;

sub tokenize {
  my $self = shift;

  while ($self->tag !~ /^(?:xsf:)?corpusData$/) {
    $self = $self->parent or return;
  };

  my $seg = $self->segmentation;
  my $tc = $self->textual_content;

  my @segments;

  my ($start, $end) = 0;
  foreach my $t (split(/([^-a-zA-ZäüöÖÄÜß]|\s+)/, $tc)) {
    $end = $start + length $t;
    if ($t =~ /\w/) {
      push(@segments, [$t, $seg->segment($start, $end)]);
    };
    $start = $end;
  };

  return @segments;
};

1;
