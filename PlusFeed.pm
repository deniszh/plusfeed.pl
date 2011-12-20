package PlusFeed;

use strict;
use warnings;
use Carp;

use Google::Plus;
require 5.10.1;
use v5.10.1;
use XML::RSS;
use utf8;

our $VERSION = '0.01';

sub new {
    my $class = shift;
    my $self  = {};
    bless $self, $class;
    $self->_initialize(@_);
    return $self;
}

sub _initialize {
    my $self = shift;
    my $hash = {@_};
    croak "Please provide Google+ API Key" if (not $hash->{key});
    $self->{_key} = $hash->{key};
    my $plus = Google::Plus->new(
        key => $hash->{key}
    );
    $self->{_plus_object} = $plus;
    croak "Please provide Google+ User Id" if (not $hash->{user});
    $self->{_user} = $hash->{user};
    my $rss = new XML::RSS(version => '2.0');
    $self->{_rss_object} = $rss;

    # page only consists 20 items for now
    # Google::Plus not supporting maxItems yet
    $self->{_pages} = $hash->{pages};
    $self->{_pages} //= 0; # default is 0 means all pages
    
    # caching
    # cache - must be already initialized CHI object
    $self->{_cache_object} = $hash->{cache};
    $self->{_cache_ttl} = $hash->{cache_ttl};
    $self->{_cache_ttl} //= 300; # default seconds

    return 1;
}

sub get_api_key {
    my $self = shift;
    return $self->{_key};
}

sub set_api_key {
    my $self = shift;
    my $key = shift;
    $self->{_key} = $key;
}

sub get_user_id {
    my $self = shift;
    return $self->{_user};
}

sub set_user_id {
    my $self = shift;
    my $user = shift;
    $self->{_user} = $user;
}

sub get_plus_object {
    my $self = shift;
    return $self->{_plus_object};
}

sub get_person_object {
    my $self = shift;
    return $self->{_person_object};
}

sub get_activities_object {
    my $self = shift;
    return $self->{_activities_object};
}

sub get_rss_object {
    my $self = shift;
    return $self->{_rss_object};
}

sub get_cache_object {
    my $self = shift;
    return $self->{_cache_object};
}

sub get_rss_stream {
    my $self   = shift;
    my $hash   = {@_};
    my $plus   = $self->{_plus_object};
    my $rss    = $self->{_rss_object};
    my $pages  = $self->{_pages};
    my $user   = $self->{_user};
    my $cache  = $self->{_cache_object};
    
    my $rss_stream;
    if (defined $cache) {
       $rss_stream  = $cache->get( 'RSS'.$user );
       return $rss_stream if defined $rss_stream;
    }
    my $person = $plus->person($user);
    $self->{_person_object} = $person;
    my $person_name = $person->{displayName};
    $rss->channel(
        title       => "Google+ for $person_name",
        link        => "https://plus.google.com/$user/posts",
        description => "Google+ RSS feed for $person_name"
    );
    # get this person's activities
    my $activities = $plus->activities($user, 'public');
    $self->{_activities_object} = $activities;
    while ($activities->{nextPageToken}) {
        my $next = $activities->{nextPageToken};
        for my $item (@{$activities->{items}}) {
    	    no warnings;
            my $object = $item->{object};
            my $body   = $item->{annotation};
            if ($body) { $body = $body . "<br />"; }
            if ($object->{attachments}) {
                for my $att (@{$object->{attachments}}) {
                    if ($att->{objectType} eq 'photo') {
                        $body =
                            $body
                          . '<a href="'
                          . $att->{fullImage}->{url}
                          . '"><img src="';
                        $body = $body . $att->{image}->{url} . "></a>";
                    }
                    else {
                        $body =
                            $body
                          . ' <a href="'
                          . $att->{url} . '">'
                          . $att->{displayName} . '</a>';
                    }
                }
            }
            if ($body) { $body = $body . "<br />"; }
            $body = $body . $item->{content};
            $rss->add_item(
                title       => $item->{title},
                description => $body,
                guid        => $item->{etag},
                url         => $item->{url},
                author      => $item->{actor}->{displayName},
                date        => $item->{published},
            );
        }
        $activities = $plus->activities($user, 'public', $next)
          if defined $next && $self->{_pages} >= 0;
        --$self->{_pages} if $self->{_pages} > 0;
    }
    # put string in cache
    $cache->set( 'RSS'.$user, $rss->as_string, $self->{_cache_ttl} ) if defined $cache;
    # renew objects
    $self->{_plus_object} = $plus;
    $self->{_rss_object} = $rss;
    return $rss->as_string;

}

1;
