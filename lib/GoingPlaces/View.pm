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

    return Template->new({ INCLUDE_PATH => dir($self->app_cwd)->subdir('templates')->stringify});
}

sub get_default_page {
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

