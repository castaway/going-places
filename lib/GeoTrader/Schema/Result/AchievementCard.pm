package GeoTrader::Schema::Result::AchievementCard;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('achievement_cards');
__PACKAGE__->add_columns(
    achievement_id => {
        data_type => 'integer',
    },
    card_id => {
        data_type => 'integer',
    },
    );

__PACKAGE__->set_primary_key('achievement_id', 'card_id');

__PACKAGE__->belongs_to('achievement', 'GeoTrader::Schema::Result::Achievement', 'achievement_id');
__PACKAGE__->belongs_to('card', 'GeoTrader::Schema::Result::Card', 'card_id');

1;
