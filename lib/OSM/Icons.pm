package OSM::Icons;
use Moose;
use MooseX::StrictConstructor;
use autodie;
use XML::Simple;
use Data::Dump::Streamer;

has 'rule_file',
  is => 'ro';

has 'rules',
  is => 'ro',
  lazy => 1,
  default => sub {shift->read_rules}
  ;

sub read_rules {
  my ($self) = @_;

  my $xml = XMLin($self->rule_file,
                  ForceArray => ['rule',
                                 'condition',
                                ],
                 );

  die unless $xml;

  return $xml->{rule};
}

sub style {
  my ($self, $node) = @_;

  my $style;

  #Dump($node);

  for my $rule (@{$self->rules}) {
    my $applies = 1;
    
    for my $cond (@{$rule->{condition}}) {
      my $value = $node->{$cond->{k}};
      
      if (defined $value) {
        if (exists $cond->{v} and $cond->{v} ne $value) {
          $applies = 0;
        }

        if (exists $cond->{b} and
            $cond->{b} eq 'yes' and
            !($value ~~ ['true', 'yes', '1'])
           ) {
          $applies = 0;
        }

        if (exists $cond->{b} and
            $cond->{b} eq 'no' and
            !($value ~~ ['false', 'no', '0'])
           ) {
          $applies = 0;
        }
      } else {
        $applies = 0;
      }
    }
    
    next unless $applies;
    
    #print "Rule applies:\n";
    #Dump($rule);

    push @{$style->{linemod}}, $rule->{linemod} if $rule->{linemod};
    for my $style_key (qw<line area icon>) {
      if ($rule->{$style_key} and
          (!$style->{$style_key} or
           ($style->{$style_key}{priority}||0) <= ($rule->{$style_key}{priority}||0))) {
          $style->{$style_key} = $rule->{$style_key};
#        exists $style->{$style_key}{src} && 
#            $style->{$style_key}{src} =~ s{\.png$}{.svg};
        if($style_key eq 'area') {
            $style->{$style_key}{colour} = [ split(/#/, $style->{$style_key}{colour}, 2) ];
        }
      }
    }

    #print "Computed style:\n";
    #Dump($style);
  }

  return $style;
}

# Possibly cache sets of attributes -> style mappings?


"One of this, one of that, one of t'other";
