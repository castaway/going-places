#!/usr/bin/env perl

use strict;
use warnings;

use JSON;
use IO::All;

use lib 'lib';
use GeoTrader::Schema;
use Data::Dump::Streamer 'Dump', 'Dumper';

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

    my $card = $schema->resultset('Card')->find_or_create(
        {
            name => $ele->{tags}{name},
            location_lat => $ele->{lat},
            location_lon => $ele->{lon},
            osm_id       => $ele->{id},
        }, 
        { key => 'osmnode' });

    if(!$card->place_id) {
        ## Ask Nominatim where it is:

        my $nom_data < io->http("http://nominatim.openstreetmap.org/reverse?format=json&osm_id=" . $ele->{id} . "&osm_type=N&zoom=18&addressdetails=1");
        my $nom = decode_json($nom_data)->{address};

        print STDERR Dumper($ele);
        print STDERR Dumper($nom);

        my $place = $schema->resultset('Place')->find_or_create(
            {
                map { $nom->{$_} ? ($_, $nom->{$_}) : () } (qw/village town city/),
                'country_code', $nom->{country_code},
            }
        );
        if($place) {
            $card->place($place);
            $card->update();
        }
        sleep 1;
#        sleep time()-$last_nominatim_time;
#        $last_nominatim_time = time();
    }

    foreach my $tag (keys %{ $ele->{tags} }) {
        next if($tag eq 'name');

        $card->find_or_create_related('tags', {
            key => $tag,
            value => $ele->{tags}{$tag},
                              });
    }
} 
