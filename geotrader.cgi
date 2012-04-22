#!/usr/bin/env perl
package GeoTrader::Web;

use Plack::Request;
use Plack::Middleware::Session;
use JSON;
use Data::Dumper;
use Web::Simple;
# use Moo;
use lib '/mnt/shared/projects/cardsapp/lib';
use GeoTrader;

has 'model' => (is => 'ro', lazy => 1, builder => '_build_model');

sub _build_model {
    return GeoTrader->new(
        base_uri => '/cgi-bin/geotrader.cgi',
        app_cwd => 'mnt/shared/projects/cardsapp',
        );
}

sub dispatch_request {
    my ($self) = @_;

    my $user;

    $self->check_authenticated($user),

    sub (GET + /) {
        my ($self) = @_;
        ## default/home page, check location, if near known node, display location page, else display users cards + "no places nearby"

        return [ 200, [ 'Content-type', 'text/html' ], [ $self->default_page() ]];
    },

    sub (POST + /login + %username=&password=) {
        my ($self, $usern, $passw) = @_;
        
#        print STDERR "user check $usern\n";
        my $user = $self->model->get_check_user($usern, $passw);


        if($user) {
#            print STDERR "Found user $usern\n";
        
            # Turtles all the way down!
            return ($self->set_authenticated($user), 
                    [ 200, [ 'Content-type', 'text/html' ], [ 'Login succeeded' ]]);
        } else {
            return [ 200, [ 'Content-type', 'text/html' ], [ 'Login failed' ]];
        }
    },

    sub (POST + /create_user + %username=&password=&display=) {
        my ($self, $usern, $passw, $display) = @_;

        ## FIXME: Check length of inputs!
        $self->model->create_user($usern, $passw, $display);

        return [ 200, [ 'Content-type', 'text/html' ], [ $self->default_page() ]];
    },

    sub (GET + /loc/*/*) {
        my ($self, $lat, $long) = @_;
        ## Test page, pass in location lat/long
        
        my $test_location = [$lat, $long];

        return [ 200, [ 'Content-type', 'text/html' ], [ default_page($test_location) ]];
    },

    sub (GET + /places + ?bbox=) {
        my ($self, $bbox) = @_;
        # west, south, east, north
        return [200, [ 'Content-type', 'text/plain' ], [''] ] if(!$bbox);

        my @bounds = split(/,/, $bbox);
        my $places = $self->model->get_places(@bounds);
        
        return [200, [ 'Content-type', 'text/plain' ], [ $places || '' ] ];
    },

    ## Store location of current user, ignore if no user?
    sub (POST + /_update_location + %lat=&lon=) {
        my ($self, $lat, $lon) = @_;

        print STDERR Dumper($_[PSGI_ENV]);

        if(!$user) {
            ## Do nutting..
            return [200, [], ['']];
        }
        
        $user->update_location($lat, $lon);
        
        return [200, [ 'Content-type', 'text/plain' ], [ 'Updated' ] ];
    },

    ## Place page for a specific card
    ## Recheck user is logged in, that latest coords are near it, and latest coords were updated > XX min ago.
    sub (GET + /cards/*) {
        my ($self, $card_desc) = @_;
    }

}

sub default_page {
    my ($self, $loc) = @_;
    my $user = $self->get_user();
    my $user_location = $loc || $self->get_location();
    my $place = $self->model->find_place($user_location);
    if($place) {
        $self->model->set_location($user, $place, $user_location);
    }
    my $page = $self->model->get_user_profile() if($user && !$place);
    $page = $self->model->get_default_page if(!$user);

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
        ${$user_ref} = $self->model->schema->resultset('User')->find($uc);
      }
      return;
    }
  );
}

sub ensure_session {
  my ($self) = @_;
  sub () {
    return if $_[PSGI_ENV]->{'psgix.session'};
    Plack::Middleware::Session->new(store => 'File');
  }
}
GeoTrader::Web->run_if_script();
