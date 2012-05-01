package GeoTrader::Schema::Result::Place;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('places');
__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_auto_increment => 1,
    },
    village => {
        data_type => 'TINYTEXT',
        is_nullable => 1,
    },
    town => {
        data_type => 'TINYTEXT',
        is_nullable => 1,
    },
    city => {
        data_type => 'TINYTEXT',
        is_nullable => 1,
    },
    county => {
        data_type => 'TINYTEXT',
        is_nullable => 1,
    },
    country_code => {
        data_type => 'TINYTEXT',
    },
);

__PACKAGE__->set_primary_key('id');

# __PACKAGE__->has_many('achievements', 'GeoTrader::Schema::Result::Acheivement', 'place_id');
__PACKAGE__->has_many('cards', 'GeoTrader::Schema::Result::Card', 'place_id');

sub location {
    my ($self) = @_;

    return $self->village ||
        $self->town ||
        $self->city ||
        $self->county ||
        '';
}

'collected';

