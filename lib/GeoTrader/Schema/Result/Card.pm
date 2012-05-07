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
    origin_point_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    max_available => {
        data_type => 'integer',
        default_value => 10,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('namepoint' => ['name', 'origin_point_id']);

__PACKAGE__->has_many('tags', 'GeoTrader::Schema::Result::Tag', 'card_id');
__PACKAGE__->has_many('achievement_cards', 'GeoTrader::Schema::Result::AchievementCard', 'card_id');
__PACKAGE__->belongs_to('origin_point', 'GeoTrader::Schema::Result::Point', 'origin_point_id', { join_type => 'LEFT' });

## Instances: Users have some, some are dropped at other points what remains is "available" (see remaining)
__PACKAGE__->has_many('user_cards', 'GeoTrader::Schema::Result::UserCards', 'card_id');
__PACKAGE__->has_many('instances', 'GeoTrader::Schema::Result::CardInstance', 'card_id');

sub remaining {
    my ($self) = @_;

    return $self->max_available 
        - $self->user_cards_rs->count
        - $self->instances->count;
}

# has an osm / origin ID?
'collected';

