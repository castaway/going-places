#!/usr/bin/env perl
package GoingPlaces::Web;

use Plack::Request;
use Plack::Middleware::Session;
use JSON;
use Data::Dumper;
use Web::Simple;
# use Moo;
use lib '/mnt/shared/projects/cardsapp/lib';
use GoingPlaces::Model;
use GoingPlaces::View;

has 'model' => (is => 'ro', lazy => 1, builder => '_build_model');
has 'view' => (is => 'ro', lazy => 1, builder => '_build_view');

has 'host' => (is  => 'ro', default => sub {'http://desert-island.me.uk' });
has 'base_uri' => (is  => 'ro', default => sub {'/cgi-bin/geotrader.cgi'});
has 'app_cwd' => ( is => 'ro', default => sub {'/mnt/shared/projects/cardsapp'});
has 'static_uri' => ( is => 'ro', default => sub {'/~castaway/cardsapp'});

sub _build_model {
    my ($self) = @_;
    return GoingPlaces::Model->new(
        base_uri => $self->base_uri,
        app_cwd => $self->app_cwd,
        );
}

sub _build_view {
    my ($self) = @_;
    return GoingPlaces::View->new(
        base_uri => $self->base_uri,
        static_uri => $self->static_uri,
        app_cwd => $self->app_cwd,
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

    sub (GET + /user/*) {
        my ($self, $user_id) = @_;
        
        my $this_user = $user_id && $self->model->find_user($user_id);
        if(!$user_id || $user_id =~ /\D/ || !$this_user) {
            return [ 404, [ 'Content-type', 'text/html' ], [ 'Not found' ] ];
        }

        return [ 200, [ 'Content-type', 'text/html' ], [ $self->view->user_profile($this_user, $user) ] ];

    },

    sub (GET + /map) {
        my ($self) = @_;

        return [200, [ 'Content-type', 'text/html' ], [ $self->view->map_page($user) ] ];
    },

    sub (POST + /login + %username=&password=&from~) {
        my ($self, $usern, $passw, $from_page) = @_;
        
        my $user = $self->model->get_check_user($usern, $passw);
        
        print STDERR "From page: $from_page\n";
        if($user) {
            # Turtles all the way down!
            return ($self->set_authenticated($user), 
                    [ 303, [ 'Content-type', 'text/html', 
                             'Location', $self->host . $self->base_uri . ($from_page || '/map') ], 
                      [ 'Login succeeded, back to <a href="' . $self->host . $self->base_uri . ($from_page || '/map') . '"></a>' ]]);
        } else {
            return [ 200, [ 'Content-type', 'text/html' ], [ 'Login failed' ]];
        }
    },

    sub (GET + /logout) {
        my ($self) = @_;

        if($user) {
            $user = undef;
        }

        return ($self->logout,
                [ 303, [ 'Content-type', 'text/html', 
                         'Location', $self->host . $self->base_uri . '/map' ], 
                      [ 'Login succeeded, back to <a href="' . $self->host . $self->base_uri . '/map' . '"></a>' ]]);
    },

    sub (POST + /register + %username=&password=&displayname~&from=) {
        my ($self, $username, $password, $displayname, $from_page) = @_;

        ## FIXME: Check length of inputs!
        my $newuser = $self->model->create_user($username, $password, $displayname);

        if($newuser) {
            return 
                [ 303, [ 'Content-type', 'text/html', 
                         'Location', $self->host . $self->base_uri . ($from_page || '/map') ], 
                  [ 'Registration succeeded, back to <a href="' . $self->host . $self->base_uri . ($from_page || '/map') . '"></a>' ]];
        } else {
            return [ 200, [ 'Content-type', 'text/html' ], [ 'Registration failed' ]];
        }
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
        my $cards = $self->model->get_cards(@bounds);
        
        return [200, [ 'Content-type', 'text/plain' ], [ $cards || '' ] ];
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

    ## Card page for a specific card
    ## Recheck user is logged in, that latest coords are near it, and latest coords were updated < XX min ago.
    sub (GET + /card/*) {
        my ($self, $card_desc) = @_;

        my ($id, $desc) = $card_desc =~ /^(\d+)-([\w\s])+/;
        print STDERR "Looking for card: $id, $desc\n";
        my $card = $self->model->find_card($id);
        my $user_card_status = $self->model->user_card_status($card, $user);

        print STDERR "Found card: ", $card->id, "\n";
        return [200, ['Content-type', 'text/html' ], [$self->view->card_page($user_card_status, $card, $user) ]];
    },

    sub (POST + /_take_card + %card_id=) {
        my ($self, $card_id) = @_;

        my $result = $self->model->take_card($card_id, $user);

        return [200, ['Content-type', 'application/json' ], [ encode_json($result) ]];
    }

}

sub default_page {
    my ($self, $loc) = @_;
    my $user = $self->get_user();
    my $user_location = $loc || $self->get_location();
    my $card = $self->model->find_card($user_location);
    if($card) {
        $self->model->set_location($user, $card, $user_location);
    }
    my $page = $self->model->get_user_profile() if($user && !$card);
    $page = $self->model->get_default_page if(!$user);

    return $card || $page;
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

sub logout { 
    my ($self) = @_;
    return (
        $self->ensure_session, 
        sub () { 
            print STDERR ref($_[PSGI_ENV]->{'psgix.session'});
            delete $_[PSGI_ENV]->{'psgix.session'}{user_info};
        }
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
GoingPlaces::Web->run_if_script();
