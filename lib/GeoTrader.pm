package GeoTrader;

use strict;
use warnings;

use Data::Dumper;
use GeoTrader::Schema;
use Template;
use Path::Class;
use URI::Escape;
use Authen::Passphrase::SaltedDigest;
use Moo;

has 'schema' => (is => 'ro', lazy => 1, builder => '_build_schema');
has 'base_uri' => (is => 'ro', required => 1);
has 'app_cwd' => (is => 'ro', required => 1);
has 'tt' => (is => 'ro', lazy => 1, builder => '_build_tt');

sub _build_schema {
    my ($self) = @_;

    return GeoTrader::Schema->connect("dbi:SQLite:/mnt/shared/projects/cardsapp/trader.db");
}

sub _build_tt {
    my ($self) = @_;

    return Template->new({ INCLUDE_PATH => dir($self->app_cwd)->subdir('templates')});
}

sub find_place {
}

sub get_default_page {
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
    my $ol_text = "lat\tlon\tid\tproximity\ttitle\tdescription\n";

    while (my $card = $card_rs->next) {
#        print STDERR Dumper($card);

        $ol_text .= $card->{location_lat}. "\t".
               $card->{location_lon}. "\t" .
               $card->{id} . "\t" .
               ## default all features to be "not close" to the user, we change
               ## this in the javascript when items are closeby
               "far\t" . 
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

sub get_check_user {
    my ($self, $username, $password) = @_;
    
    my $user = $self->schema->resultset('User')->find({ username => $username });
    if($user && $user->password->match($password)) {
        return $user;
    }
    
    return;
}

sub create_user {
    my ($self, $username, $password, $displayn) = @_;
    
    my $user = $self->schema->resultset('User')->find({ username => $username });
    if($user) {
        warn "Cowardly refusing to re-create an existing user $username";
        return;
    }

    $self->schema->resultset('User')->create({
        username => $username,
        password => Authen::Passphrase::SaltedDigest->new(algorithm => "SHA-1", salt_random => 20, passphrase=>$password),
        display_name => $displayn,
                                             });
    
    return $user;
}

sub get_user_card_places {
}

1;
