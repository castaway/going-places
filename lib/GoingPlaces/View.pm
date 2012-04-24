package GoingPlaces::View;

use strict;
use warnings;

use Template;
use Path::Class;

use Moo;

has 'base_uri' => (is => 'ro', required => 1);
has 'static_uri' => (is => 'ro', required => 1);
has 'app_cwd' => (is => 'ro', required => 1);
has 'tt' => (is => 'ro', lazy => 1, builder => '_build_tt');

sub _build_tt {
    my ($self) = @_;

    return Template->new({ 
        INCLUDE_PATH => dir($self->app_cwd)->subdir('templates')->stringify,
        WRAPPER      => 'wrapper.tt',
                         });
}

sub get_default_page {
}

sub place_page {
    my ($self, $card_row, $user_row) = @_;

    # pre-template data mungings
    my $has_card = $user_row && $user_row->user_cards_rs->find({ $card_row->id });
    
    my $output = '';
    $self->tt->process('place_page.tt',
                       {
                           user => $user_row,
                           card => $card_row,
                           has_card => $has_card,
                       },
                       \$output )
        || die $self->tt->error;

    return $output;
}

sub map_page {
    my ($self, $user) = @_;

    my $output = '';
    $self->tt->process('map_page.tt', 
                       { 
                           user => $user,
                           static_uri => $self->static_uri,
                       }, \$output)
        || die $self->tt->error;

    return $output;
}

