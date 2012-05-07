package GoingPlaces::Model;

use strict;
use warnings;

use Data::Dumper;
use GeoTrader::Schema;
use Template;
use Path::Class;
use Geo::Ellipsoid;
use URI::Escape;
use Authen::Passphrase::SaltedDigest;
use Moo;

has 'schema' => (is => 'ro', lazy => 1, builder => '_build_schema');
has 'base_uri' => (is => 'ro', required => 1);
has 'app_cwd' => (is => 'ro', required => 1);

sub _build_schema {
    my ($self) = @_;

    return GeoTrader::Schema->connect("dbi:SQLite:/mnt/shared/projects/cardsapp/trader.db");
}

sub find_card {
    my ($self, $id) = @_;

    return $self->schema->resultset('Card')->find({ id => $id });
}

sub find_user {
    my ($self, $id) = @_;

    return $self->schema->resultset('User')->find({ id => $id });
}

## currently using "cards" should be using new "points"!
sub _is_close {
    my ($self, $user, $card, $accuracy) = @_;
    ## Magic number!
    $accuracy ||= 20;

    return 0 if(!$user->current_latlon);

    my $earth = Geo::Ellipsoid->new(ell => 'WGS84',
                                 units => 'degrees',
                                 # 1 -- symmetric -- -180..180
                                 longitude => 1,
                                 bearing => 1,
                                );
    # How far is the (last-known-location) of the user from the cards loc?
    ## This should account for last update time of loc too!
    my $dist = $earth->range($card->origin_point->location_lat, 
                             $card->origin_point->location_lon,
                             $user->current_latlon->latitude,
                             $user->current_latlon->longitude);

    ## Magic number!
    return 0 if($dist > $accuracy);

    return 1;    
}

sub take_card {
    my ($self, $id, $user) = @_;

    my $card = $self->schema->resultset('Card')->find({ id => $id });
    return { error => 'No such card' } if(!$card);

    my $is_close = $self->_is_close($user, $card);
    if(!$is_close) {
        return { error => "Too far away "};
    }

    $user->user_cards->create({card_id => $card->id});

    return { $card->get_columns };
}

sub user_card_status {
    my ($self, $card_row, $user_row) = @_;
    
    # pre-template data mungings
    my $has_card = $user_row && $user_row->user_cards_rs->search({ card_id => $card_row->id })->count;
    my $is_here  = $user_row && $self->_is_close($user_row, $card_row) && 1; # check coords last updated against card coords!
    my $cards_remaining = $card_row->remaining;


    my $user_status = { map { $_ => 'hidden'} (qw/no_user has_card here_and_cards here_no_cards not_here/)};
    if(!$user_row) {
        $user_status->{no_user} = 'visible';
    } elsif($has_card) {
        $user_status->{has_card} = 'visible';
    } elsif($cards_remaining && $is_here) {
        $user_status->{here_and_cards} = 'visible';
    } elsif($is_here) {
        $user_status->{here_no_cards} = 'visible';
    } else {
        $user_status->{not_here} = 'visible';
    }

    return $user_status;
}


# -1.8342449951171,51.543991149077,-1.7257550048829,51.576007442191
sub get_cards {
    my ($self, $west, $south, $east, $north) = @_;

    my $points_rs = $self->schema->resultset('Point')->search({
        location_lat => { '>=' => $south },
        location_lat => { '<=' => $north },
        location_lon => { '>=' => $west  },
        location_lon => { '<=' => $east  },
      },
      {
          prefetch => {'card' => 'tags'},
      }
        );

    return $self->write_openlayers_text($points_rs);
}

## Stolen from BGGUsers::Utils
## Should use point ids soon, not card ids?
sub write_openlayers_text {
    my ($self, $points_rs) = @_;

    $points_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my $ol_text = "lat\tlon\tid\tproximity\ttitle\tdescription\n";

    while (my $point = $points_rs->next) {
#        print STDERR Dumper($point);

        $ol_text .= $point->{location_lat}. "\t".
               $point->{location_lon}. "\t" .
               $point->{card}{id} . "\t" .
               ## default all features to be "not close" to the user, we change
               ## this in the javascript when items are closeby
               "far\t" . 
               $point->{card}{name}. "\t" .
               '<span id="card-' . $point->{card}{id} .
               '" class="card-link">' . 
#               '" class="card-link" style="display:none">' . 
               $self->get_card_link($point->{card}) . '</span><br>' .
               join('<br>', map { $_->{key} . ":" . $_->{value} } (@{ $point->{card}{tags} })).
               ($point->{card}{photo} ? '<img src="' . $point->{card}{photo} . '">' : '');
        
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

    $user = $self->schema->resultset('User')->create({
        username => $username,
        password => Authen::Passphrase::SaltedDigest->new(algorithm => "SHA-1", salt_random => 20, passphrase=>$password),
        display_name => $displayn,
                                             });
    
    return $user;
}

sub get_user_card_cards {
}

1;
