package GeoTrader::Schema::Result::Tag;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('tags');

__PACKAGE__->add_columns(
    card_id => {
        data_type => 'integer',
    },
    key => {
        data_type => 'TINYTEXT',
    },
    value => {
        data_type => 'TINYTEXT',
    },
    );

__PACKAGE__->set_primary_key('card_id', 'key');

__PACKAGE__->belongs_to('card', 'GeoTrader::Schema::Result::Card', 'card_id');

'tagged';
