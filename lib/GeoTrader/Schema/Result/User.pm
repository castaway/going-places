package GeoTrader::Schema::Result::User;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->load_components(qw(InflateColumn::Authen::Passphrase));
__PACKAGE__->table('users');
__PACKAGE__->add_columns(
    id => {
        data_type => 'integer',
        is_auto_increment => 1,
    },
    username => {
        data_type => 'varchar',
        size => 50,
    },
    password => {
        data_type => 'varchar',
        size => 255,
        inflate_passphrase => 'rfc2307',
    },
    display_name => {
        data_type => 'varchar',
        size => 50,
    },
    );

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('username' => ['username']);

__PACKAGE__->has_many('user_cards', 'GeoTrader::Schema::Result::UserCards', 'user_id');
__PACKAGE__->has_many('user_achievements', 'GeoTrader::Schema::Result::UserAchievement', 'user_id');
__PACKAGE__->might_have('current_latlon', 'GeoTrader::Schema::Result::UserLatLon', 'user_id',);

sub name {
    my ($self) = @_;

    return $self->display_name || $self->username;
}

sub update_location {
    my ($self, $lat, $lon) = @_;

    my $loc = $self->find_or_new_related('current_latlon',
                                         { latitude => $lat,
                                           longitude => $lon }
        );
    if($loc->in_storage) {
        $loc->latitude($lat);
        $loc->longitude($lon);
        $loc->update();
    } else {
        $loc->insert();
    }

}

sub has_achievement {
    my ($self, $achievement) = @_;

    return $self->user_achievements->search({ achievement_id => $achievement->id });
}

1;

    
