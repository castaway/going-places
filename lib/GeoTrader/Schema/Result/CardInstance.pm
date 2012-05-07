package GeoTrader::Schema::Result::CardInstance;

use strict;
use warnings;

use base 'DBIx::Class::Core';

## Track dropped cards, also "specials" with no origin point

__PACKAGE__->table('card_instances');
__PACKAGE__->add_columns(
    card_id => {
        data_type => 'integer',
    },
    point_id => {
        data_type => 'integer',
    },
);

__PACKAGE__->set_primary_key('card_id', 'point_id');

__PACKAGE__->belongs_to('card', 'GeoTrader::Schema::Result::Card', 'card_id');
__PACKAGE__->belongs_to('point', 'GeoTrader::Schema::Result::Point', 'point_id');

'collected';

