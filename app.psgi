#!/usr/bin/env plackup
use Plack::App::Path::Router;
use Plack::App::File;
use Path::Router;
use PlusFeed;
use CHI;
use CHI::Driver::Redis;

our $APIKEY   = 'APIKEY';
our $BASE_URL = 'http://deniszh.org.ua:5000';

my $cache = CHI->new(
    driver    => 'Redis',
    namespace => 'plusfeed',
    server    => '127.0.0.1:6379',
    debug     => 0
);
my $router = Path::Router->new;

$router->add_route(
    '/' => target => sub {
        my ($request) = @_;
        my $response = $request->new_response(200);
        $response->content_type('text/html');
        $response->body($homepage);
    }
);

$router->add_route(
    '/:userid/?:pages' => validations => {
        userid => 'Int',
        pages  => 'Int'
    },
    target => sub {

        # matches are passed to the target sub ...
        my ($request, $userid, $pages) = @_;
        if ($pages eq '') { $pages = 0; }
        my $plus = PlusFeed->new(
            key   => $APIKEY,
            user  => $userid,
            pages => $pages,
            cache => $cache
        );
        my $rss_stream = $plus->get_rss_stream();
        my $response   = $request->new_response(200);
        $response->content_type('text/xml');
        $response->body($rss_stream);
    }
);

our $homepage = <<"__HOMEPAGE__";
<html>
       	<head>
		<title>PlusFeed - Unofficial Google+ User Feeds</title>
		<link rel="stylesheet" type="text/css" href="/static/style.css">
		<script type="text/javascript" src="https://apis.google.com/js/plusone.js"></script>
		</head>
		<body>
				<div id="gb">
						<span>$countmsg</span>
						<a href="http://plus.google.com">Google+</a>
				</div>
				<div id="header">
						<h1>PlusFeed</h1>
						<h2>Unofficial Google+ User Feeds</h2>
						<span id="plusone"><g:plusone size="tall"></g:plusone></span>
				</div>
				<div id="content">
						<div id="intro">
								<h2>
								Want a <span class="stress">feed</span> for your Google+ posts?
								</h2>
								<div id="inst">
								<p>
								Simply add a Google+ user number to the end of this site's URL to get an RSS feed of <em>public</em> posts.
								</p>
								<p>
								Example: <a href="$BASE_URL/112714787808356482431">$BASE_URL/<strong>112714787808356482431/</strong></a>
								</p>
								<p>
								<br/>
								You can grab the source for this app on GitHub <a href="https://github.com/deniszh/plusfeed.pl">here</a>.
								</p>
								<p>
								<em>Originally created by <a href="http://www.russellbeattie.com">Russell Beattie</a></em></br>
								<em>Perl port by <a href="http://deniszh.org.ua">Denis Zhdanov</a></em>
								</p>
								</div>
						</div>
				</div>
				<!--
				<script type="text/javascript">
				  var _gaq = _gaq || [];
				  _gaq.push(['_setAccount', 'UA-24604146-1']);
				  _gaq.push(['_trackPageview']);
				  (function() {
						var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
						ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
						var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
				  })();
				</script>
				-->
	     </body>
</html>
__HOMEPAGE__

# now create the Plack app
my $app = Plack::App::Path::Router->new(router => $router);

use Plack::Builder;
builder {
    my $static = Plack::App::File->new(root => "./static");
    mount "/static"      => $static;
    mount "/favicon.ico" => $static;
    mount "/robots.txt"  => $static;
    mount "/"            => $app;
};
