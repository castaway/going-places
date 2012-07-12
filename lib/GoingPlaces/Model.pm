package GoingPlaces::Model;

use strict;
use warnings;

use Data::Dumper;
use GeoTrader::Schema;
use OSM::Icons;
use Template;
use Path::Class;
use Geo::Ellipsoid;
use URI::Escape;
use Authen::Passphrase::SaltedDigest;
use Graphics::Color::HSV;
#use List::Util 'min', 'max';
use Moo;

has 'schema' => (is => 'ro', lazy => 1, builder => '_build_schema');
has 'base_uri' => (is => 'ro', required => 1);
has 'app_cwd' => (is => 'ro', required => 1);

sub _build_schema {
    my ($self) = @_;

    return GeoTrader::Schema->connect("dbi:SQLite:/mnt/shared/projects/cardsapp/trader.db");
}

sub find_card {
    my ($self, $id, $prefetch) = @_;

    return $self->schema->resultset('Card')->as_subselect_rs->search(
        { 'me.id' => $id },
        { prefetch => $prefetch })->first;
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

sub claim_achievement {
    my ($self, $id, $user) = @_;

    my $achievement = $self->schema->resultset('Achievement')->find({ id => $id });
    return { error => 'No such achievement'} if(!$achievement);

    my $cards_rs = $achievement->achievement_cards;

    my $a_cards = $user->user_cards->search({
        'me.card_id' => { '-in' => [ map { $_->id } $cards_rs->all] },
                                 });

    if($a_cards->count != $cards_rs->count) {
        return { error => 'You do not have all the cards for that achievement!' };
    }
    
    $user->achievement_cards->create({ achievement_id => $achievement->id });
    $a_cards->delete;

    return { $achievement->get_columns };
}

## Should probably JSONify/session store this!
## Given a User and a Card (user optional)
## a) Check if user already has Card
## b) Check if user is in home location of card
##  - Need to add check for cards that are not in home loc?
## c) Check how many instances of this card can be picked up
## d) Check if User has achievements this card belongs to
## e) Check if User has any of the others in achievements this card belongs to
## f) Check if User has all achievement cards
## f) Check which cards User has overall.
sub user_card_status {
    my ($self, $card_row, $user_row) = @_;
    # pre-template data mungings
    my $has_card = $user_row && $user_row->user_cards_rs->search({ card_id => $card_row->id })->count;
    my $is_here  = $user_row && $self->_is_close($user_row, $card_row) && 1; # check coords last updated against card coords!
    my $cards_remaining = $card_row->remaining;

    my $user_status = { map { $_ => 'hidden'} (qw/no_user has_card here_and_cards here_no_cards not_here/)};


 #   $user_row->result_source->schema->storage->debug(1);
    ## Verify if: 1)user has any of the achievements this card is in 2) whether user has all cards in achievement
    if($user_row) {
        my $achievement_cards = $card_row->achievement_cards_rs->search({}, { prefetch => { achievement => 'user_achievements' } });
        foreach my $ach_card ($achievement_cards->all) {
            my $id = $ach_card->achievement_id;

            ## Achievements user has completed
            if($achievement_cards->search({
                'user_achievements.user_id' => $user_row->id,
                'me.achievement_id' => $id
                                                   })
                ) {
                $user_status->{'achievements'}{$id}{visibilty} = 'visible';
                
            }

            print STDERR "Achievement: $id\n";
            ## All the OTHER cards in this achievement that our user already has
            my $cards_ach_rs = $ach_card->search_related('achievement')->search_related('achievement_cards')->search_related('card',
                {
                    'user.id' => $user_row->id,
                },
                { join => { 'user_cards' => 'user' }},
                );
            
            while (my $my_card = $cards_ach_rs->next) {
                $user_status->{'achievements'}{$id}{cards}{$my_card->id} = 'visible';
            }

#            print STDERR Data::Dumper::Dumper($user_status->{achievements}{$id});
            if(scalar keys %{ $user_status->{'achievements'}{$id}{cards} } == $ach_card->search_related('achievement')->search_related('achievement_cards')->count) {
                $user_status->{'achievements'}{$id}{all_cards} = 1;
            }

        }

    }
    
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

#    $user_row->result_source->schema->storage->debug(0);
    return $user_status;
}


# -1.8342449951171,51.543991149077,-1.7257550048829,51.576007442191
sub get_cards {
    my ($self, $user, $west, $south, $east, $north) = @_;

    my $points_rs = $self->schema->resultset('Point')->search({
        #'location_lat' => { '-between' => [$south, $north] },
        #'location_lon' => { '-between' => [$west, $east] },
        'location_lat' => { '-between' => [sort { $a <=> $b } ($south, $north)] },
        'location_lon' => { '-between' => [sort { $a <=> $b } ($west, $east)] },
      },
      {
          prefetch => {'card' => [ 'tags', { user_cards => 'user' }] },
      }
        );

    ## Should colour the cards the current user is already holding?

    $points_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @points = $points_rs->all;
    foreach my $point (@points) {
#        print STDERR "Card, User: ", Dumper($point->{card}), " ", Dumper({$user->get_columns}). "\n";
        if(exists $point->{card}{user_cards} && $user && grep { $_->{user_id} == $user->id } @{$point->{card}{user_cards} }) {
            $point->{proximity} = 'owned';
            print STDERR "Colour changed: ", Dumper($point), "\n";
        }
    }

    return \@points;
    return [$points_rs->all()];
}

#->new({ value => 1, saturation => 1, hue => 360*($i/($n+1))  })->as_rgb->as_css_hex
# DBIC_TRACE=1 perl -Ilib  geotrader.cgi /achievements?bbox=-1.7800429153441,51.559973319754,-1.7799570846559,51.560026680242

# Inputs: -1.7800429153441, 51.559973319754, -1.7799570846559, 51.560026680242

sub get_achievements_cards {
    my ($self, $west, $south, $east, $north) = @_;

#     print STDERR "Inputs: $west, $south, $east, $north\n";
#     my $points_rs = $self->schema->resultset('Point')->search({
#          location_lat => { '>=' => $south },
#          location_lat => { '<=' => $north },
#          location_lon => { '>=' => $west  },
#          location_lon => { '<=' => $east  },
# #        'location_lat' => { '-between' => [$south, $north] },
# #        'location_lon' => { '-between' => [$east, $west] },
#       },
#       {
#          prefetch => {'achievement_cards' => { 'card' => 'origin_point' }},
#       }
#         );

#     print STDERR "Point count: ", $points_rs->count, "\n";

#     my $achievements_rs = $points_rs->search_related('card')->
#         search_related('achievement_cards')->search_related('achievement');

    my $achievements_rs = $self->schema->resultset('Achievement')->search({
        'origin_point.location_lat' => { '-between' => [sort { $a <=> $b } ($south, $north)] },
        'origin_point.location_lon' => { '-between' => [sort { $a <=> $b } ($west, $east)] },
      },
      {
          prefetch => {'achievement_cards' => { 'card' => 'origin_point' }},
      }
        );

    $achievements_rs->result_class('DBIx::Class::ResultClass::HashRefInflator');
    my @points;
    my $total = $achievements_rs->count;
    print STDERR "Total: $total\n";

    my $loop = 0;
    foreach my $ach ($achievements_rs->all) {

        print  STDERR Dumper($ach);

        my $colour = Graphics::Color::HSV->new({
            value => 1, saturation => 0.5,
            hue => ( 360 * ( $loop++ / ($total + 1) ) ),
                                                })->to_rgb->as_css_hex;

        foreach my $a_card (@{$ach->{achievement_cards}}) {
            my $point = $a_card->{card}{origin_point};
            $point->{card} = $a_card->{card};
            delete $point->{card}{origin_point};
            $point->{colour} = $colour;

            push @points, $point; #  if $loop == 3;
        }

    }

#    print STDERR Dumper(\@points);
    return \@points;
#    return $self->write_openlayers_text(\@points);
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
