#!/usr/bin/env perl
package GeoTrader::Web;

use Plack::Request;
use JSON;
use Web::Simple;
use lib '/mnt/shared/projects/cardsapp/lib';
use GeoTrader;

sub dispatch_request {
    my $gt = GeoTrader->new(base_uri => '/cgi-bin/geotrader.cgi');

    sub (GET + /) {
        my ($self) = @_;
        ## default/home page, check location, if near known node, display location page, else display users cards + "no places nearby"

        return [ 200, [ 'Content-type', 'text/html' ], [ $self->default_page($gt) ]];
    },

    sub (GET + /loc/*/*) {
        my ($self, $lat, $long) = @_;
        ## Test page, pass in location lat/long
        
        my $test_location = [$lat, $long];

        return [ 200, [ 'Content-type', 'text/html' ], [ default_page($gt, $test_location) ]];
    },

    sub (GET + /places + ?bbox=) {
        my ($self, $bbox) = @_;
        # west, south, east, north
        return [200, [ 'Content-type', 'text/plain' ], [''] ] if(!$bbox);

        my @bounds = split(/,/, $bbox);
        my $places = $gt->get_places(@bounds);
        
        return [200, [ 'Content-type', 'text/plain' ], [ $places || '' ] ];
    }
}

sub default_page {
    my ($self, $gt, $loc) = @_;
    my $user = $self->get_user();
    my $user_location = $loc || $self->get_location();
    my $place = $gt->find_place($user_location);
    if($place) {
        $gt->set_location($user, $place, $user_location);
    }
    my $page = $gt->get_user_profile() if($user && !$place);
    $page = $gt->get_default_page if(!$user);

    return $place || $page;
}

sub get_user {
}

sub get_location {
    my ($self) = @_;
    my $gt_cookie = Plack::Request->new($_[PSGI_ENV])->cookies->{'_geotrader'};
    my $loc = decode_json($gt_cookie)->{location};
}

GeoTrader::Web->run_if_script();
