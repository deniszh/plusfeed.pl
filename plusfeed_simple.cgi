#!/usr/bin/perl
#
use PlusFeed;
my $plus = PlusFeed->new(key => 'APIKEY', user => 'USER', pages => 0);

binmode(STDOUT, ":utf8");
print "Content-type: text/xml\n\n";
print $plus->get_rss_stream();
