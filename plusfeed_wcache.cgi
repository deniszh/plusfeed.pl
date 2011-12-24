#!/usr/bin/perl
#
use PlusFeed::Atom;
use CHI;
use CHI::Driver::Redis;

my $cache = CHI->new(
                 driver => 'Redis',
                 namespace => 'plusfeed',
                 server => '127.0.0.1:6379',
                 debug => 0
);
my $plus = PlusFeed::Atom->new(key => 'APIKEY', user => 'USER', pages => 0, cache => $cache, cache_ttl => 300);

binmode(STDOUT, ":utf8");
print "Content-type: text/xml\n\n";
print $plus->get_atom_stream();
