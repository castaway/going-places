#!/usr/bin/env perl
package GeoTrader::Web;

use Plack::Request;
use Plack::Middleware::Session;
use JSON;
use Web::Simple;
use lib '/mnt/shared/projects/cardsapp/lib';
use GeoTrader;

# sub dispatch_request {
#   sub (/admin/...) {
#     Web::Simple::Thingy::Auth->new(
#       users_rs => $schema->resultset('User'),
#       make_authed_app => sub { my $user = shift; sub { [ 200, ...
#       make_unauthed_app => sub {
#         my $try_login = shift;
#         ...
#         if ($try_login->($user,$pass)) {
#         ...

sub dispatch_request {
    my ($self) = @_;

    my $user;
    my $gt = GeoTrader->new(base_uri => '/cgi-bin/geotrader.cgi');

    $self->check_authenticated($user);

    sub (GET + /) {
        my ($self) = @_;
        ## default/home page, check location, if near known node, display location page, else display users cards + "no places nearby"

        return [ 200, [ 'Content-type', 'text/html' ], [ $self->default_page($gt) ]];
    },

    sub (GET|POST + /login + ?username=&password=) {
        my ($self, $usern, $passw) = @_;
        
        my $user = $gt->get_check_user($usern, $passw);

        if($user) {
            $self->set_authenticated($user);
        } else {
            return [ 200, [ 'Content-type', 'text/html' ], [ 'Login failed' ]];
        }
    },

    sub (POST + /create_user + ?username=&password=&display=) {
        my ($self, $usern, $passw, $display) = @_;

        ## FIXME: Check length of inputs!
        $gt->create_user($usern, $passw, $display);

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
    },

    ## Store location of current user, ignore if no user?
    sub (POST + /_update_location/ + ?lat=&lon=) {
    },

    ## Place page for a specific card
    ## Recheck user is logged in, that latest coords are near it, and latest coords were updated > XX min ago.
    sub (GET + /cards/*) {
        my ($self, $card_desc) = @_;
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
#    my $gt_cookie = Plack::Request->new($_[PSGI_ENV])->cookies->{'_geotrader'};
#    my $loc = decode_json($gt_cookie)->{location};
}

## Auth from http://sherlock.scsys.co.uk/~matthewt/auth-sketch2.txt
sub set_authenticated {
  my ($self, $user) = @_;
  my $uc = $user->ident_condition;
  return (
    $self->ensure_session,
    sub () { $_[PSGI_ENV]->{'psgix.session'}{'user_info'} = $uc; }
  );
}

sub check_authenticated {
  my ($self) = @_;
  my $user_ref = \$_[1];
  return (
    $self->ensure_session,
    sub () {
      if (my $uc = $_[PSGI_ENV]->{'psgix.session'}{'user_info'}) {
        ${$user_ref} = $self->users_rs->find($uc);
      }
      return;
    }
  );
}

sub ensure_session {
  my ($self) = @_;
  sub () {
    return if $_[PSGI_ENV]->{'psgix.session'};
    Plack::Middleware::Session->new;
  }
}
GeoTrader::Web->run_if_script();
