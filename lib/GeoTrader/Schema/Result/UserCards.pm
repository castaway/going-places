package GeoTrader::Schema::Result::UserCards;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('user_cards');
__PACKAGE__->add_columns(
    user_id => {
        data_type => 'integer',
        is_auto_increment => 1,
    },
    card_id => {
        data_type => 'varchar',
        size => 50,
    },
    );

## Only one instance of each card per user?
__PACKAGE__->set_primary_key('user_id', 'card_id');

__PACKAGE__->belongs_to('user', 'GeoTrader::Schema::Result::User', 'user_id');
__PACKAGE__->belongs_to('card', 'GeoTrader::Schema::Result::Card', 'card_id');

1;

    
