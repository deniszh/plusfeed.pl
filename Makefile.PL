#
# For Heroku deployment using
# heroku create plusfeed-pl --stack cedar --buildpack http://github.com/miyagawa/heroku-buildpack-perl.git
#

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME      => 'plusfeed.pl',
    VERSION   => '0.03',
    AUTHOR    => 'Denis Zhdanov <deniszhdanov@gmail.com>',
    EXE_FILES => ['app.psgi'],
    PREREQ_PM => {
        'Google::Plus'             => '0.004',
        'XML::RSS'                 => '1.49',
        'XML::Atom::SimpleFeed'    => '0.86',
        'Plack::App::Path::Router' => '0',
        'Plack::App::File'         => '0',
        'Plack::Builder'           => '0',
        'Path::Router'             => '0.11',
        'CHI'                      => '0.5',
        'Starman'                  => '0.3',
    },
    test => {TESTS => 't/*.t'}
);
