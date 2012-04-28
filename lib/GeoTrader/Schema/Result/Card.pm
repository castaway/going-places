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
    ## Open streetmap original node id, for referring back to source
    ## also Nominatim lookups
    osm_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    ## UK at least, county + country?
    place_id => {
        data_type => 'integer',
        is_nullable => 1,
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
__PACKAGE__->has_many('user_cards', 'GeoTrader::Schema::Result::UserCards', 'card_id');
__PACKAGE__->belongs_to('place', 'GeoTrader::Schema::Result::Place', 'place_id');

# has an osm / origin ID?
'collected';

