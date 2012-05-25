#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use IO::All;

use lib 'lib';
use GeoTrader::Schema;
use Data::Dump::Streamer 'Dump', 'Dumper';

my $PHOTO_DIR = '/mnt/shared/projects/cardsapp/photos/';

my $osm_file = join('',<>);
my $osm = decode_json($osm_file);

my $schema = GeoTrader::Schema->connect("dbi:SQLite:trader.db");
$schema->deploy if !-e 'trader.db';

my $last_nominatim_time = time();
foreach my $ele (@{ $osm->{elements} }) {
    my @our_tags;

    next if(!$ele->{tags}{name});

    for my $amenity_type (qw<fuel pub parking cinema theatre pharmacy post_office crematorium place_of_worship school recycling fast_food restaurant hospital police library bar doctors veterinary dentist cafe kindergarten car_rental telephone public_building bus_station bank arts_centre community_centre bicycle_parking college>, 'paddling pool') {
      if ($ele->{tags}{amenity} && $ele->{tags}{amenity} eq $amenity_type) {
        push @our_tags, $amenity_type;
      }
    }

    next if $ele->{tags}{amenity} ~~ [
        'emergency_phone', 
        'toilets',
        'post_box',
        ];

    if ($ele->{tags}{religion}) {
      push @our_tags, $ele->{tags}{religion};
    }


    # if (!@our_tags) {
    #   Dump $ele;
    #   die;
    # }


    my $point = $schema->resultset('Point')->find_or_create(
        {
            location_lat => $ele->{lat},
            location_lon => $ele->{lon},            
            osm_id       => $ele->{id},
        }, 
        { key => 'osmnode' });

    my $photo = $ele->{id} . '_600x400.JPG';
    
    my $card = $point->find_or_create_related('card',
        {
            name => $ele->{tags}{name},
            ( -e "$PHOTO_DIR/$photo" ? ( photo => $photo) : () ),
        },
        { key => 'namepoint' });

    if(!$point->place_id) {
        ## Ask Nominatim where it is:

        my $nom_data < io->http("http://nominatim.openstreetmap.org/reverse?format=json&osm_id=" . $ele->{id} . "&osm_type=N&zoom=18&addressdetails=1");
        my $nom = decode_json($nom_data)->{address};

        print STDERR Dumper($ele);
        print STDERR Dumper($nom);

        if($nom) {
            my $place = $schema->resultset('Place')->find_or_create(
                {
                    map { $nom->{$_} ? ($_, $nom->{$_}) : () } (qw/village town city county country_code/),
                }
                );
            if($place) {
                $point->place($place);
                $point->update();
            }
            sleep 1;
#        sleep time()-$last_nominatim_time;
#        $last_nominatim_time = time();
        }
    }

    foreach my $tag (keys %{ $ele->{tags} }) {
        next if($tag eq 'name');

        $card->find_or_create_related('tags', {
            key => $tag,
            value => $ele->{tags}{$tag},
                              });
    }
} 
