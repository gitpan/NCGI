package NCGI::Cookie;
# ----------------------------------------------------------------------
# Copyright (C) 2005 Mark Lawrence <nomad@null.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# ----------------------------------------------------------------------
# HTTP Cookie object for NCGI
# ----------------------------------------------------------------------
use strict;
use warnings;
use Carp;
use Digest::MD5 qw(md5_hex);
use CGI::Util qw(escape unescape);
use overload '""' => \&_as_string, 'fallback' => 1;

our $VERSION = '0.01';
my $now = time;

#
# This routine takes (name,value,minutes_to_live,path,domain) as arguments
# to set a cookie.
#
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
        name    => '',
        value   => 0,
        expires => 0,
        path    => '/',
        domain  => '',
        @_,
    };
    bless ($self, $class);

    $self->{name}  = escape(cookie_scrub($self->{name}));
    $self->{value} = $self->{value} ? escape(cookie_scrub($self->{value})) :
                     md5_hex(md5_hex($now . {} . rand() . $$));

    $self->{expires} = 60 * $self->{expires};
    return $self;
}

sub name {
    my $self = shift;
    $self->{name} = cookie_scrub(shift) if (@_);
    return $self->{name};
}

sub value {
    my $self = shift;
    $self->{value} = cookie_scrub(shift) if (@_);
    return $self->{value};
}

sub expires {
    my $self = shift;
    $self->{expires} = 60 * shift if (@_);
    return $self->{expires};
}

sub path {
    my $self = shift;
    $self->{path} = @_ if (@_);
    return $self->{path};
}

sub domain {
    my $self = shift;
    $self->{domain} = @_ if (@_);
    return $self->{domain};
}


#
# This routine removes cookie of (name) by setting the expiration
# to a date/time GMT of (now - 24hours)
#
sub expire_cookie() {
    my $self = shift;
    $self->{expires} = -1440;
}

sub _as_string {
    my $self = shift;

    my $str = $self->{name} .'='. $self->{value}.';';
    $str   .= ' expires=' . cookie_date($self->{expires}) . ';' 
                                                 if ($self->{expires});
    $str   .= ' path=' . $self->{path} .';'      if ($self->{path});
    $str   .= ' domain=' . $self->{domain} . ';' if ($self->{domain});
    return $str;
}


#
# Class FUNCTIONs
#

#
# Utility function.
#
# '=' and ';' are not valid in the name or data components of cookies
#
sub cookie_scrub {
  my $str = shift;
  $str =~ s/(\;|\=)//g;
  return $str;
}

#
# Return a HASHREF of Cookies recieved
#
sub fetch {
    my @pairs = split(/\;\s*/, $ENV{HTTP_COOKIE} ? $ENV{HTTP_COOKIE} : '');
    my $hashref = {};
    foreach my $sets (@pairs) {
        my ($key,$val) = split(/=/, $sets);
        $hashref->{unescape($key)} = unescape($val);
    }
    return $hashref;
}


#
# this routine accepts the number of seconds to add to the server
# time to calculate the expiration string for the cookie. Cookie
# time is ALWAYS GMT!
#
sub cookie_date() {

  my ($seconds) = @_;

  my %mn = ('Jan','01', 'Feb','02', 'Mar','03', 'Apr','04',
            'May','05', 'Jun','06', 'Jul','07', 'Aug','08',
            'Sep','09', 'Oct','10', 'Nov','11', 'Dec','12' );
  my $sydate=gmtime($now + $seconds);
  my ($day, $month, $num, $time, $year) = split(/\s+/,$sydate);
  my    $zl=length($num);
  if ($zl == 1) { 
    $num = "0$num";
  }

  my $retdate="$day $num-$month-$year $time GMT";

  return $retdate;
}


1;
__END__

=head1 NAME

NCGI::Cookie - HTTP GET/POST Cookie object for NCGI

=head1 SYNOPSIS

  use NCGI::Cookie;
  my $q = NCGI::Cookie->new();

  if ($q->isquery) {
    print "GET\n" if $q->isget();
    print "POST\n" if $q->isget();
    print "Your submit button is called: ",$q->query->{'submit'};
  }

=head1 DESCRIPTION

B<NCGI::Cookie> provides a simple HTTP Cookie object for use
in the Rekudos framework. In most cases Rekudos Module authors will not
need to use this module/object as NCGI::Main creates 
$NCGI::Globals::header for that purpose.

=head1 METHODS

=head2 new( ), new($content_type)

Create a new NCGI::Cookie object, optionally specifying a content type.

=head2 $header->status($status)

Set or get the string representing the status of the HTTP response. There
is no validity checking when setting so you should read the
HTTP specification for valid strings (eg '200 OK'). This has no default.

=head2 $header->content_type($type)

Set or get the string representing the Content-Type of the HTTP response.
There is no validity checking when setting so you should read the
HTTP/MIME specifications for valid strings. The default is 'text/html'.

=head2 $header->location($location)

Set or get the string representing the Location of a HTTP redirection.
There is no validity checking when setting so you should read the
HTTP specification for valid strings. This has no default.

=head2 $header->_as_string( )

Returns a string representation of the HTTP Cookie.

=head2 $header->_print( )

Print the HTTP header to STDOUT. Exactly the same as
'print $header->_as_string;'.

=head1 SEE ALSO

L<NCGI>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Mark Lawrence E<lt>nomad@null.netE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut
