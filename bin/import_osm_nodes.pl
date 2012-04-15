#!/usr/bin/env perl

use strict;
use warnings;

use JSON;

use lib 'lib';
use GeoTrader::Schema;

my $osm_file = join('',<>);
my $osm = decode_json($osm_file);

my $schema = GeoTrader::Schema->connect("dbi:SQLite:trader.db");
$schema->deploy;

foreach my $ele (@{ $osm->{elements} }) {
    next if(!$ele->{tags}{name});

    my $card = $schema->resultset('Card')->create({
        name => $ele->{tags}{name},
        location_lat => $ele->{lat},
        location_lon => $ele->{lon},
                                       });
    
    foreach my $tag (keys %{ $ele->{tags} }) {
        next if($tag eq 'name');

        $card->create_related('tags', {
            key => $tag,
            value => $ele->{tags}{$tag},
                              });
    }
} 
