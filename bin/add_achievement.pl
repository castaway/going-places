#!/usr/bin/env perl

use strict;
use warnings;

use v5.10.0;

use List::MoreUtils 'all';

use lib 'lib';
# use Algorithm::Kmeanspp;
use Algorithm::Cluster::KMeansMinMax;
use Data::Dumper;

use GeoTrader::Schema;
use Graphics::Color::HSV;

## perl bin/add_achievement.pl "pub" "Bristol"

my $schema = GeoTrader::Schema->connect('dbi:SQLite:trader.db');

## Tag based achievements, eg "pub" "Swindon"
my $amenity = shift;
my $place = shift;
## 1-10 1= easy (busroute?), 10 = mount everest
my $difficulty = shift || 2;

my $place_rs = $schema->resultset('Place')->search({ 
    '-or' => 
        [
         { village => $place },
         { town => $place },
         { city => $place },
        ],
        country_code => 'gb',
    });

my $cards_rs = $place_rs->as_subselect_rs->search_related('points')->search_related('card')->search(
    {
        'tags.key' => 'amenity',
        'tags.value' => $amenity,
    },
    {
        join => ['tags'],
        prefetch => ['origin_point'],
    });

print "Found, ", $cards_rs->count, "\n";
## clusterize as we need groups of 10 or less.
if($cards_rs->count > 10) {
    ## clusterize:

#    my $clusters = ak_clusters($cards_rs);
    my $clusters = akmm_clusters($cards_rs);

#     my $loop_count = 0;
#     while(!check_clusters($clusters) || $loop_count++ >= 10) {
#         print "Loop: $loop_count\n";
#         $cards_rs->reset;
#         $clusters = akmm_clusters($cards_rs);
#     }

    foreach my $cluster (@{ $clusters }) {
        print STDERR "Cluster\n";
        print STDERR Dumper($cluster->{members});
        add_achievement(map { $_->{id} } @{ $cluster->{members} });
    }

    ## debug centers
    print "lat\tlon\tproximity\tfillColor\ttitle\tdescription\n";
    foreach my $cluster_i (0..@{$clusters}-1) {
        my $cluster = $clusters->[$cluster_i];
        
        print join("\t",
                   $cluster->{center}{data}[0], $cluster->{center}{data}[1],
                   'near',
                   get_color($cluster_i, @$clusters+0),
                   "CENTER", "CENTER OF CLUSTER $cluster_i"), "\n";
        
        for my $member (@{$cluster->{members}}) {
            print join("\t",
                       $member->{data}[0], $member->{data}[1], 
                       'far',
                       get_color($cluster_i, @$clusters+0),
                       "MEMBER", "MEMBER OF CLUSTER $cluster_i"), "\n";
        }
    }
}

sub get_color {
    my ($count, $total) = @_;
    # count should range from 0..$total-1.

    # print "get_color($count, $total)\n";

    my $colour = Graphics::Color::HSV->new({
        value => 1, saturation => 0.5,
        hue => ( 360 * ( $count / ($total + 1) ) ),
                                           })->to_rgb->as_css_hex;
    
}

sub check_clusters {
    my ($clusters) = @_;

    return all { @$_ >= 5 } @$clusters ;
}

sub akmm_clusters {
    my ($cards_rs) = @_;

    my @cdata = ();
    while (my $card = $cards_rs->next) {
        push @cdata, { id => $card->id,
                       data => [
                           $card->origin_point->location_lat,
                           $card->origin_point->location_lon,
                           ],
        };
    }

    my $ak = Algorithm::Cluster::KMeansMinMax->new(
        data => \@cdata, 
        max_size => 12,
#        min_size => 4,
        initial_k => int($cards_rs->count / 10),
        );
    return $ak->cluster(10);
}

sub ak_clusters {
    my ($cards_rs) = @_;
    
    my $ak = Algorithm::Kmeanspp->new();
    while(my $card = $cards_rs->next) {
        $ak->add_document(
            $card->id,
            {
                lat => $card->origin_point->location_lat,
                lon => $card->origin_point->location_lon,
            }
            );
    }

#    $ak->do_clustering(int($cards_rs->count / 10)+2, 20);
    $ak->do_clustering(10, 5);
    ## maybe intead of #iterations we should do until coderef returns true?

    
#    print Dumper($ak->clusters);
#    print Dumper($ak->centroids);

    return $ak->clusters;
}

sub add_achievement {
    my (@card_ids) = @_;

    state @achievements;
    push @achievements, "${place}-${amenity}-".@achievements;


    my $achievement = $schema->resultset('Achievement')->find_or_create(
        {
            name => $achievements[-1],
            category => $amenity,
            details => '', # should be nullable
            difficulty => $difficulty,
            achievement_cards => [
                map { { card_id => $_ } } @card_ids,
                ],
        });

    # my $cards_rs = $schema->resultset('Card')->search(
    #     { 'me.id' => \@card_ids }, 
    #     { prefetch => { origin_point => 'place' }}
    # );

    # while(my $card = $cards_rs->next) {
    #     print "Found: " . $card->name, "\n";
    #     print "At:    " . $card->origin_point->location_lat, ", ", $card->origin_point->location_lon, "\n";


    #     $card->create_related('achievement_cards',
    #                           {
    #                               achievement => {
    #                                   name => $achievements[-1],
    #                                   category => $amenity,
    #                                   details => '', # should be nullable
    #                                   difficulty => $difficulty,
    #                               },
    #                           }
    #         );
    # }
}
