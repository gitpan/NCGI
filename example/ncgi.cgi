#!/usr/bin/perl
#!/usr/bin/speedy
# ----------------------------------------------------------------------
# Copyright (C) 2005-2007 Mark Lawrence <nomad@null.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# ----------------------------------------------------------------------
# ncgi.cgi - Example NCGI script
# ----------------------------------------------------------------------
use strict;
use warnings;
use NCGI;
use NCGI::Cookie;

our $DEBUG = 1;

my $x = NCGI->r->xhtml;

$x->_set_lang('en');
$x->h1('Title');
$x->p('text and more text');

warn "a quick warning";
warn "debug: a quick debug";

$x->p('You made a GET query')  if NCGI->query->isget;
$x->p('You made a POST query') if NCGI->query->ispost;

my $c = NCGI::Cookie->new(name => 'cookie', value => '23049230492304230');
NCGI->response->header->_add_set_cookie($c);

NCGI->respond;

