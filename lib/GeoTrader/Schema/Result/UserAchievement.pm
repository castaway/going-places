package GeoTrader::Schema::Result::UserAchievement;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('user_achievements');
__PACKAGE__->add_columns(
    achievement_id => {
        data_type => 'integer',
    },
    user_id => {
        data_type => 'integer',
    },
    );

__PACKAGE__->set_primary_key('achievement_id', 'user_id');

__PACKAGE__->belongs_to('achievement', 'GeoTrader::Schema::Result::Achievement', 'achievement_id');
__PACKAGE__->belongs_to('user', 'GeoTrader::Schema::Result::User', 'user_id');

1;
