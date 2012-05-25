package GeoTrader::Schema::Result::Achievement;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('achievements');
__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_auto_increment => 1,
    },
    name => {
        data_type => 'varchar',
        size => 255,
    },
    category => {
        data_type => 'varchar',
        size => 255,
    },
    details => {
        data_type => 'varchar',
        size => 1024,
        is_nullable => 1,
    },
    difficulty => {
        data_type => 'integer',
    });

__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many('achievement_cards', 'GeoTrader::Schema::Result::AchievementCard', 'achievement_id');

1;
