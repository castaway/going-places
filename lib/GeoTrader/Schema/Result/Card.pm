package GeoTrader::Schema::Result::Card;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('cards');
__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_auto_increment => 1,
    },
    name => {
        data_type => 'TINYTEXT',
    },
    photo => {
        data_type => 'TINYTEXT',
        is_nullable => 1,
    },
    details => {
        data_type => 'TEXT',
        is_nullable => 1,
    },
    location_lat => {
        data_type => 'float',
    },
    location_lon => {
        data_type => 'float',
    },
    max_available => {
        data_type => 'integer',
        default_value => 10,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many('tags', 'GeoTrader::Schema::Result::Tag', 'card_id');
# has an osm / origin ID?
'collected';

