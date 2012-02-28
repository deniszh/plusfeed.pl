package PlusFeed;

use strict;
use warnings;
use Carp;

use Google::Plus;
require 5.10.1;
use XML::RSS;
use utf8;

our $VERSION = '0.04';

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
    my $plus = Google::Plus->new(key => $hash->{key});
    $self->{_plus_object} = $plus;
    croak "Please provide Google+ User Id" if (not $hash->{user});
    $self->{_user} = $hash->{user};
    my $rss = new XML::RSS(version => '2.0');
    $self->{_rss_object} = $rss;

    # page only consists 20 items for now
    # Google::Plus not supporting maxItems yet
    $self->{_pages} = $hash->{pages};
    $self->{_pages} //= 0;    # default is 0 means all pages

    # caching
    # cache - must be already initialized CHI object
    $self->{_cache_object} = $hash->{cache};
    $self->{_cache_ttl}    = $hash->{cache_ttl};
    $self->{_cache_ttl}  //= 300;    # default seconds
    
    # if no_updates is true updates will be not translated (Atom only)
    $self->{_no_updates}   = $hash->{no_updates};

    return 1;
}


# make body of RSS entry using G+ activity item
# many raw html magic :)
sub _make_body {
    my $self = shift;
    my $item = shift;

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
                $body = $body . $att->{image}->{url} . '"></a>';
            }
            elsif ($att->{objectType} eq 'video') {
                $body = $body . '<a href="' . $att->{url} . '"><img src="';
                $body = $body . $att->{image}->{url} . '"></a>';
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
    $body = $body . $object->{content};
    $body = $body . '&nbsp;<a href="' . $object->{url} . '">...</a>';

    return $body;
}

### put string in cache
sub _cache_put {
    my $self      = shift;
    my $string    = shift;
    my $namespace = shift;
    my $key       = shift;

    my $cache = $self->{_cache_object};
    return if not defined $cache;

    # put string in cache
    $cache->set($namespace . $key, $string, $self->{_cache_ttl});
}

### get tring from cache
sub _cache_get {
    my $self      = shift;
    my $namespace = shift;
    my $key       = shift;

    my $cache = $self->{_cache_object};
    return if not defined $cache;

    return $cache->get($namespace . $key);
}

sub get_rss_stream {
    my $self  = shift;
    my $hash  = {@_};
    my $plus  = $self->{_plus_object};
    my $rss   = $self->{_rss_object};
    my $pages = $self->{_pages};
    my $user  = $self->{_user};

    my $rss_stream = $self->_cache_get('RSS', $user);
    return $rss_stream if defined $rss_stream;

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
            my $body = $self->_make_body($item);
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
    $self->_cache_put('RSS', $user, $rss->as_string);

    # renew objects
    $self->{_plus_object} = $plus;
    $self->{_rss_object}  = $rss;
    return $rss->as_string;

}

### accessors below
### was added for clarity :)

sub get_api_key {
    my $self = shift;
    return $self->{_key};
}

sub set_api_key {
    my $self = shift;
    my $key  = shift;
    $self->{_key} = $key;
    $self->_initialize(
        key       => $self->{_key},
        user      => $self->{_user},
        pages     => $self->{_pages},
        cache     => $self->{_cache},
        cache_ttl => $self->{_cache_ttl}
    );
}

sub get_user_id {
    my $self = shift;
    return $self->{_user};
}

sub set_user_id {
    my $self = shift;
    my $user = shift;
    $self->{_user} = $user;
    $self->_initialize(
        key       => $self->{_key},
        user      => $self->{_user},
        pages     => $self->{_pages},
        cache     => $self->{_cache},
        cache_ttl => $self->{_cache_ttl}
    );
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

1;
