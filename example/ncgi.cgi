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
use utf8;
use NCGI;
use NCGI::Cookie;

our $DEBUG = 1;

my $q = NCGI->q;
my $x = NCGI->r->xhtml;

$x->_set_lang('en');


$x->_goto('head');
$x->style_open(-type => 'text/css');
$x->_css('    body {
        padding: 1em;
        font: 1em "Trebuchet MS",Trebuchet,Arial,Verdana,Sans-serif;
    }
    div {
        border: 1px solid #ddd;
        margin: 1em 0em;
        padding: .5em;
    }'); 
$x->style_close;


$x->_goto('body');


$x->h1_open;
$x->a(-href => '.', 'NCGI Test');
$x->h1_close;

$x->p('A quick example for GET and POST queries using NCGI');

warn "a quick warning";
warn "debug: a quick debug";


$x->form_open(-method => 'get', -action => '.');
$x->div_open('Please enter something: ');
$x->input(
    -name => 'something',
    -type => 'text',
    -value => $q->param('something') || '¥ £ € $ ¢',
);
$x->input(
    -name => 'submit',
    -type => 'submit',
    -value => 'GET',
);

if (my $text = $q->param('something') and $q->isget) {
    $x->p('Your GET: '.$text);
}


$x->div_close;
$x->form_close;

$x->form_open(-method => 'post', -action => '.');
$x->div_open('Please enter something: ');
$x->input(
    -name => 'something',
    -type => 'text',
    -value => $q->param('something') || '¥ £ € $ ¢',
);
$x->input(
    -name => 'submit',
    -type => 'submit',
    -value => 'POST',
);

if (my $text = $q->param('something') and $q->ispost) {
    $x->p('Your POST: '.$text);
}

$x->div_close;
$x->form_close;

my $c = NCGI::Cookie->new(name => 'cookie', value => '23049230492304230');
NCGI->response->header->_add_set_cookie($c);

NCGI->respond;

