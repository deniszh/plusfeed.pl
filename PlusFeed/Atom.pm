package PlusFeed::Atom;
use strict;
use warnings;
use parent qw( PlusFeed );

our $VERSION = '0.01';

use Carp;
use Google::Plus;
require 5.10.1;
use XML::Atom::SimpleFeed;
use utf8;


sub get_atom_stream {
    my $self = shift;
    return $self->get_rss_stream(@_);
}

sub get_rss_stream {
    my $self  = shift;
    my $hash  = {@_};
    my $plus  = $self->{_plus_object};
    my $rss   = $self->{_rss_object};
    my $pages = $self->{_pages};
    my $user  = $self->{_user};

    my $rss_stream = $self->_cache_get('Atom', $user);
    return $rss_stream if defined $rss_stream;

    my $person = $plus->person($user);
    $self->{_person_object} = $person;
    my $person_name = $person->{displayName};

    # get this person's activities
    my $act = $plus->activities($user, 'public');
    $self->{_activities_object} = $act;

    # override RSS object with Atom
    $rss = XML::Atom::SimpleFeed->new(
        title   => $act->{title},
        link    => $act->{selfLink},
        id      => $act->{id},
        updated => $act->{updated},
    );

    while ($act->{nextPageToken}) {
        my $next = $act->{nextPageToken};
        for my $item (@{$act->{items}}) {
            my $body = $self->_make_body($item);
            $rss->add_entry(
                title     => $item->{title},
                content   => $body,
                id        => $item->{etag},
                link      => $item->{url},
                author    => $item->{actor}->{displayName},
                published => $item->{published},
            );
        }
        $act = $plus->activities($user, 'public', $next)
          if defined $next && $self->{_pages} >= 0;
        --$self->{_pages} if $self->{_pages} > 0;
    }

    # put string in cache
    $self->_cache_put('Atom', $user, $rss->as_string);

    # renew objects
    $self->{_plus_object} = $plus;
    $self->{_rss_object}  = $rss;
    return $rss->as_string;

}

1;
