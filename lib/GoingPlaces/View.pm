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

sub user_profile {
    my ($self, $user_row, $current_user) = @_;

    return $self->_process_tt('user_profile.tt',
                              {
                                  this_user => $user_row,
                                  user => $current_user,
                              }
        );
}

sub card_page {
    my ($self, $user_status, $card_row, $user_row) = @_;

    ## Will splodey if there is no "amenity" value
    ## Ideally we display a "pub" image?
    my $amenity_tag = $card_row->tags_rs->find({ key => 'amenity'});
    my $is_a = $amenity_tag ? $amenity_tag->value() : '';

    ## Do we "reserve" the card while the user is looking at the page
    ## in case of multiple people standing here?
    return $self->_process_tt('card_page.tt',
                       {
                           user => $user_row,
                           card => $card_row,
                           user_status => $user_status,
                       } );
}

sub map_page {
    my ($self, $user) = @_;

    return $self->_process_tt('map_page.tt', 
                       { 
                           user => $user,
                       });
}

sub _process_tt {
    my ($self, $template, $vars) = @_;

    my $output = '';
    $self->tt->process($template,
                       { 
                           static_uri => $self->static_uri,
                           base_uri   => $self->base_uri,
                           %$vars,
                       }, \$output)
        || die $self->tt->error;

    return $output;
    
}
