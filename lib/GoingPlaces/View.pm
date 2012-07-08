package GoingPlaces::View;

use strict;
use warnings;

use Template;
use Path::Class;
use URI::Escape;

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
    my ($self, $user_status, $card_row, $user_row, $styleinfo) = @_;

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
                           card_style => $styleinfo,
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

sub achievements_page {
    my ($self, $user) = @_;

    return $self->_process_tt('achievements_page.tt', 
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

## Stolen from BGGUsers::Utils
## Should use point ids soon, not card ids?

## Card popup contents should be dynamic, or hold JSON in the page with all data which js can update and pull from there?
sub write_openlayers_text {
    my ($self, $points) = @_;

    my $ol_text = "lat\tlon\tid\tfillColor\tproximity\ttitle\tdescription\n";

    foreach my $point (@$points) {
#        print STDERR Dumper($point);

        my $colour = $point->{colour} || '#ee9900';
        $ol_text .= 

            ## Location
            $point->{location_lat}. "\t".
            $point->{location_lon}. "\t" .

            ## Card ID
            $point->{card}{id} . "\t" .

            ## Colour
            $colour . "\t" . 

            ## Distance from user right now:
            ## default all features to be "not close" to the user, we change
            ## this in the javascript when items are closeby
            ($point->{proximity} || "far") . "\t" . 

            ## Card Name (title) for popup
            $point->{card}{name}. "\t" .

            ## Popup content
            '<span id="card-' . $point->{card}{id} .
            '" class="card-link">' . 
            $self->get_card_link($point->{card}) . '</span><br>' .
            join('<br>', map { $_->{key} . ":" . $_->{value} } (@{ $point->{card}{tags} })). '<br>' .
            ($point->{card}{photo} ? '<img src="' . $self->static_uri . '/photos/' . $point->{card}{photo} . '" height="200px" width="300px">' : '') .

            '<div><button id="take_card"><img src="' . $self->static_uri . '/icons/' .
            ($point->{proximity} || '' eq 'owned'
             ? 'Farm-Fresh_delete.png'
             : 'Farm-Fresh_add.png' ) .
            '"/></button></div>' .
            
            '<script>GP.card = { id: '.$point->{card}{id}.'}</script>'
            ;
        
        $ol_text .= "\n";
    }

    return $ol_text;
}

sub get_card_link {
    my ($self, $card) = @_;

    return '<a href="' 
        . $self->base_uri 
        . '/card/' 
        . $card->{id} . '-' . uri_escape($card->{name})
    . '">' 
        . $card->{name}. '</a>'
        ;
}
