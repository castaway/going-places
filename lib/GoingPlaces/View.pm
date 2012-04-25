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
    my $has_card = $user_row && $user_row->user_cards_rs->search({ card_id => $card_row->id })->count;
    my $is_here  = $user_row && 1; # check coords last updated against card coords!
    my $cards_remaining = $card_row->max_available - $card_row->user_cards_rs->count;    

    ## Will splodey if there is no "amenity" value
    ## Ideally we display a "pub" image?
    my $is_a = $card_row->tags_rs->find({ key => 'amenity'})->value();

    ## Do we "reserve" the card while the user is looking at the page
    ## in case of multiple people standing here?
    my $output = '';
    $self->tt->process('place_page.tt',
                       {
                           static_uri => $self->static_uri,
                           base_uri   => $self->base_uri,
                           user => $user_row,
                           card => $card_row,
                           has_card => $has_card,
                           is_here  => $is_here,
                           cards_remaining => $cards_remaining,
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

