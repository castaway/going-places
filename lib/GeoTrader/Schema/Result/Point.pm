package GeoTrader::Schema::Result::Point;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('points');
__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_auto_increment => 1,
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
    location_lat => {
        data_type => 'float',
    },
    location_lon => {
        data_type => 'float',
    },
    is_visible => {
        data_type => 'integer',
        default_value => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('osmnode' => ['osm_id']);

__PACKAGE__->belongs_to('place', 'GeoTrader::Schema::Result::Place', 'place_id');
__PACKAGE__->might_have('card', 'GeoTrader::Schema::Result::Card', 'origin_point_id');
__PACKAGE__->has_many('instances', 'GeoTrader::Schema::Result::CardInstance', 'point_id');

'collected';

