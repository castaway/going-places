package GeoTrader;

use strict;
use warnings;

use Data::Dumper;
use GeoTrader::Schema;
use URI::Escape;
use Moo;

has 'schema' => (is => 'ro', lazy => 1, builder => '_build_schema');
has 'base_uri' => (is => 'ro', required => 1);

sub _build_schema {
    my ($self) = @_;

    return GeoTrader::Schema->connect("dbi:SQLite:/mnt/shared/projects/cardsapp/trader.db");
}

# -1.8342449951171,51.543991149077,-1.7257550048829,51.576007442191
sub get_places {
    my ($self, $west, $south, $east, $north) = @_;

    my $places_rs = $self->schema->resultset('Card')->search({
        location_lat => { '>=' => $south },
        location_lat => { '<=' => $north },
        location_lon => { '>=' => $west  },
        location_lon => { '<=' => $east  },
      },
      {
          prefetch => 'tags',
      }
        );

    return $self->write_openlayers_text($places_rs);
}

## Stolen from BGGUsers::Utils
sub write_openlayers_text {
    my ($self, $card_rs) = @_;

    $card_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my $ol_text = "lat\tlon\tid\ttitle\tdescription\n";

    while (my $card = $card_rs->next) {
#        print STDERR Dumper($card);

        $ol_text .= $card->{location_lat}. "\t".
               $card->{location_lon}. "\t" .
               $card->{id} . "\t" .
               $card->{name}. "\t" .
               '<span id="card-' . $card->{id} .
               '" class="card-link" style="display:none">' . 
               $self->get_card_link($card) . '</span><br>' .
               join('<br>', map { $_->{key} . ":" . $_->{value} } (@{ $card->{tags} })).
               ($card->{photo} ? '<img src="' . $card->{photo} . '">' : '');
        
        $ol_text .= "\n";
    }

    return $ol_text;
}

sub get_card_link {
    my ($self, $card) = @_;

    return '<a href="' 
        . $self->base_uri 
        . '/card/' 
        . $card->{id} . '-' . uri_escape($card->{name})
    . '">' 
        . $card->{name}. '</a>'
        ;
}

sub get_user_card_places {
}

1;
