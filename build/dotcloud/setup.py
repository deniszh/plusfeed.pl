## Copyright (c) 2010 dotCloud Inc.
##
## Permission is hereby granted, free of charge, to any person obtaining a copy
## of this software and associated documentation files (the "Software"), to deal
## in the Software without restriction, including without limitation the rights
## to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
## copies of the Software, and to permit persons to whom the Software is
## furnished to do so, subject to the following conditions:
##
## The above copyright notice and this permission notice shall be included in
## all copies or substantial portions of the Software.
##
## THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
## IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
## FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
## AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
## LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
## OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
## THE SOFTWARE.

from setuptools import setup

VERSION = '0.4.3'

setup(
        name                = 'dotcloud',
        version             = VERSION,
        author              = 'dotCloud Inc.',
        author_email        = 'support@dotcloud.com',
        url                 = 'http://www.dotcloud.com/',
        description         =
        'dotCloud meta-package to automatically install the dotCloud CLI',
        long_description    =
        'This package does not provide anything per se. It contains a single '
        'dependency on dotcloud.cli, the CLI allowing to manage your '
        'software deployments on the dotCloud platform.'
        '\n'
        'Using dotCloud, you can assemble your stack from pre-configured and '
        'heavily tested components. dotCloud supports major application '
        'servers, databases and message buses. '
        '\n'
        'The dotCloud CLI allows you to manage your software deployments on '
        'the dotCloud platform. To use this tool, you will need a dotCloud '
        'account. Register at http://www.dotcloud.com/ to get one!',
        package_dir         = {'dotcloud': '.'},
        packages            = ['dotcloud'],
        install_requires    = ['dotcloud.cli == {0}'.format(VERSION)],
        zip_safe            = False
)
