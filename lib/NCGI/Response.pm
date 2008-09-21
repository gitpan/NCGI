package NCGI::Response;
use 5.006;
use strict;
use warnings;
use Carp;
use NCGI::Response::Header;
use XML::API;

our $VERSION = '0.10';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self  = {
        header      => NCGI::Response::Header->new,
    };

    bless($self, $class);
    return $self;
}


sub header {
    my $self = shift;
    return $self->{header};
}


sub content {
    my $self = shift;
    if ($self->{content}) {
        return $self->{content};
    }
    return $self->xhtml;
}


sub xhtml {
    my $self = shift;
    if ($self->{xhtml}) {
        return $self->{xhtml};
    }

    $self->{xhtml} = XML::API->new(doctype => 'xhtml');
    $self->{xhtml}->html_open;
    $self->{xhtml}->_set_id('html');

    $self->{xhtml}->head_open(undef);
    $self->{xhtml}->_set_id('head');
    $self->{xhtml}->head_close();

    $self->{xhtml}->body_open(undef);
    $self->{xhtml}->_set_id('body');

    $self->{content} = $self->{xhtml};
    return $self->{xhtml};
}


sub rss {
    my $self = shift;

    if ($self->{rss}) {
        return $self->{rss};
    }

    $self->{rss} = XML::API->new(doctype => 'rss');
    $self->{content} = $self->{rss};
    return $self->{rss};
}


sub text {
    croak 'text not implemented yet';
#    $self->{content} = $self->{text};
}


sub as_string {
    my $self   = shift;
    my $action = shift || '_as_string';

    if ($action !~ m/_as_string|_fast_string/) {
        croak 'usage: as_string([_fast_string])';
    }

    if (!$self->{content}) {
        croak 'No content to display (must call xhtml/rss/text first)';
    }

    #
    # Set some interesting headers
    #
    my $x = $self->{content};
    if ($x->_langs) {
        $self->{header}->content_language(join(',', $x->_langs));
    }

    my $type = $x->_content_type;
    if (ref($x) eq 'XML::API::XHTML') {
        if ($ENV{HTTP_ACCEPT} and
            $ENV{HTTP_ACCEPT} !~ m/application\/xhtml\+xml/) {
            $type = 'text/html';
        }
    }
    $self->{header}->content_type($type .  '; charset='. $x->_encoding);

    my $doc = $self->{content}->$action;

    do { # don't want number of unicode characters...
        use bytes;
        $self->{header}->content_length(length($doc));
    };

    return $self->{header}->_as_string() . $doc;
}


sub fast_string {
    my $self = shift;
    return $self->as_string('_fast_string');
}


1;
__END__

=head1 NAME

NCGI::Response - Represent A CGI Response

=head1 SYNOPSIS

  use NCGI::Response;
  my $r = NCGI::Response->new();

  my $h = $r->header;
  $h->custom_header('value');

  my $x = $r->xhtml;
  $x->_encoding('ISO-8859-1');
  $x->_goto('head');
  $x->_set_lang('en');
  $x->title('A Simple Example');

  print $r->as_string();

  # Content-Length: 302
  # Content-Type: application/xhtml+xml; charset=ISO-8859-1
  # Custom-Header: value
  # Content-Language: en
  #
  # <?xml version="1.0" encoding="ISO-8859-1" ?>
  # <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN"
  #     "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
  # <html xml:lang="en" xmlns="http://www.w3.org/1999/xhtml">
  # <head>
  #     <title>A Simple Example</title>
  # </head>
  # <body></body>
  # </html>

=head1 DESCRIPTION

B<NCGI::Response> represents a reply to a HTTP request. It is basically
a container for an L<NCGI::Response::Header> object and an L<XML::API>
object.

Some headers such as Content-Type, Content-Language are automatically
derived from the content object when as_string is called.

B<NCGI::Response> objects are usually created and accessed through the
L<NCGI> 'header' function.

=head1 METHODS

=head2 new

Create a new B<NCGI::Response> object. An L<NCGI::Header> object is
automatically instantiated, but none of the content objects exist yet.

=head2 header

Returns the L<NCGI::Header> object.

=head2 xhtml

Returns a reference to an XML::API::XHTML object, creating it on the
first call. Sets an internal content pointer so that this object is
the one used to generate content by the as_string() method.

=head2 rss

Returns a reference to an XML::API::RSS object, creating it on the
first call. Sets an internal content pointer so that this object is
the one used to generate content by the as_string() method.

Not implemented yet.

=head2 text

Returns a reference to an XML::API::TEXT object, creating it on the
first call. Sets an internal content pointer so that this object is
the one used to generate content by the as_string() method.

Not implemented yet.

=head2 content

Compatibility function. Returns xhtml().

=head2 as_string

Returns the header and the content as a string suitable for sending
directly to the browser. The content used depends on the last xhtml()
or rss() or text() call.

=head2 fast_string

Returns the header and the content as a string suitable for sending
directly to the browser. Uses the XML::API _fast_string method of
generating the content.

=head1 SEE ALSO

L<CGI::Simple>, L<NCGI>, L<NCGI::Response::Header>
L<XML::API>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

Feel free to send me a mail telling me if you have used this module.
Until now I'm the only known user...

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut

