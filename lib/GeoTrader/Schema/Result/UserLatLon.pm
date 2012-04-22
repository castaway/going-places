package GeoTrader::Schema::Result::UserLatLon;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('user_latlon');
__PACKAGE__->add_columns(
    user_id => {
        data_type => 'integer',
    },
    latitude => {
        data_type => 'float',
    },
    longitude => {
        data_type => 'float',
    }
    );

__PACKAGE__->set_primary_key('user_id');

__PACKAGE__->belongs_to('user', 'GeoTrader::Schema::Result::User', 'user_id');

1;

    
