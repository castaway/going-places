#!/usr/bin/env perl

use strict;
use warnings;

use GeoTrader::Schema;

my $schema = GeoTrader::Schema->connect('dbi:SQLite:trader.db');

my $amenity = shift;
my $place = shift;

$place = $schema->resultset('Place')->search([
    { village => $place },
    { town => $place },
    { city => $place },
                                             );

