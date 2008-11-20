package NCGI::Cookie;
use strict;
use warnings;
use Carp qw(croak);
use Digest::MD5 qw(md5_hex);
use CGI::Util qw(escape unescape);
use overload '""' => \&_as_string, 'fallback' => 1;

our $VERSION = '0.12';

# ----------------------------------------------------------------------
# Class Functions
# ----------------------------------------------------------------------

#
# Return a HASHREF of Cookies recieved
#
sub fetch {
    my $src = shift || $ENV{HTTP_COOKIE} || '';
    my @pairs = split(/\;\s*/, $src);
    my $hashref = {};
    foreach my $sets (@pairs) {
        my ($key,$val) = split(/=/, $sets);
        if (exists($hashref->{unescape($key)})) {
            if (ref($hashref->{unescape($key)}) eq 'ARRAY') {
                push(@{$hashref->{unescape($key)}}, unescape($val));
            }
            else {
                $hashref->{unescape($key)} =
                    [$hashref->{unescape($key)}, unescape($val)];
            }
        }
        else {
            $hashref->{unescape($key)} = unescape($val);
        }
    }
    return $hashref;
}

# ----------------------------------------------------------------------
# Object Methods
# ----------------------------------------------------------------------

#
# This routine takes (name,value,epoch,path,domain) as arguments
# to set a cookie.
#
sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
        name    => undef,
        value   => undef,
        expires => time + 60*60*24,
        max_age => undef,
        path    => '/',
        domain  => undef,
        @_,
    };
    bless ($self, $class);

    $self->{name}  = escape(_cookie_scrub($self->{name}));
    $self->{value} = $self->{value} ? escape(_cookie_scrub($self->{value})) :
                     md5_hex(md5_hex(time . {} . rand() . $$));

    return $self;
}

sub name {
    my $self = shift;
    $self->{name} = _cookie_scrub(shift) if (@_);
    return $self->{name};
}

sub value {
    my $self = shift;
    $self->{value} = _cookie_scrub(shift) if (@_);
    return $self->{value};
}

sub expires {
    my $self = shift;
    $self->{expires} = shift if (@_);
    return $self->{expires};
}

sub max_age {
    my $self = shift;
    $self->{max_age} = _cookie_scrub(shift) if (@_);
    return $self->{max_age};
}

sub path {
    my $self = shift;
    $self->{path} = _cookie_scrub(shift) if (@_);
    return $self->{path};
}

sub domain {
    my $self = shift;
    $self->{domain} = _cookie_scrub(shift) if (@_);
    return $self->{domain};
}


sub expire_cookie() {
    my $self = shift;
    $self->{expires} = 1;
}

sub _as_string {
    my $self = shift;

    unless(defined($self->{name}) and defined($self->{value})) {
        croak('Cookie Name and Value must be defined');
    }

    my $str = $self->{name} .'='. $self->{value}.';';
    $str   .= ' Path=' . $self->{path} .';'      if ($self->{path});
    $str   .= ' Domain=' . $self->{domain} . ';' if ($self->{domain});
    $str   .= ' Max-Age=' . $self->{max_age} . ';'
        if (defined($self->{max_age}));
    $str   .= ' Expires=' . _cookie_date($self->{expires}) . ';' 
        if (defined($self->{expires}));
    $str   .= ' Version=1';
    return $str;
}


# ----------------------------------------------------------------------
# Private/Utility function.
# ----------------------------------------------------------------------

#
# '=' and ';' are not valid in the name or data components of cookies
#
sub _cookie_scrub {
  my $str = shift;
  $str =~ s/(\;|\=)//g if(defined($str));
  return $str;
}


#
# this routine accepts the number of seconds to add to the server
# time to calculate the expiration string for the cookie. Cookie
# time is ALWAYS GMT!
#
sub _cookie_date() {
  my $when = shift;

  my %mn = ('Jan','01', 'Feb','02', 'Mar','03', 'Apr','04',
            'May','05', 'Jun','06', 'Jul','07', 'Aug','08',
            'Sep','09', 'Oct','10', 'Nov','11', 'Dec','12' );

  my $sydate = gmtime($when);
  my ($day, $month, $num, $time, $year) = split(/\s+/,$sydate);

  if (length($num) == 1) { 
    $num = "0$num";
  }

  my $retdate="$day $num-$month-$year $time GMT";

  return $retdate;
}


1;
__END__

=head1 NAME

NCGI::Cookie - HTTP Cookie object for NCGI

=head1 SYNOPSIS

  use NCGI::Cookie;

  # subroutine for reading cookies from the query
  my $hashref      = NCGI::Cookie::fetch();
  my $cookie_value = $hashref->{cookie_name};

  # object methods for creating cookies to send in the response
  my ($name, $value, $epoch, $path, $domain) =
    ('c1','value',1221397599,'/',undef);
  my $c = NCGI::Cookie->new(
    name    => $name,
    value   => $value,
    expires => $epoch,
    path    => $path,
    domain  => $domain,
  );

  # You can also "print $c->_as_string;"
  print $c; # c1=value; expires=Tue 07-Jun-2005 12:02:01 GMT; path=/


=head1 DESCRIPTION

B<NCGI::Cookie> provides a simple HTTP Cookie object for Cookie creation,
and a fetch subroutine to retrieve cookies sent by a browser.

=head1 SUBROUTINES

=head2 fetch

Returns a HASH reference containing all Cookies sent by the browser.

=head1 METHODS

=head2 new( ... )

Create a new NCGI::Cookie object with parameters 'name', 'value',
'expires', 'path' and 'domain'. Only 'name' and 'value' are really
necessary as expires will automatically be filled in otherwise.

=head2 name

Set or Get the name of the cookie

=head2 value

Set or Get the value of the cookie. Will be scrubbed for illegal characters.

=head2 expires

Set or Get the expiration value of the cookie as a unix epoch.

=head2 max_age

Set or Get the expiration value of the maximum age of the cookie
in seconds.

=head2 path

Set or Get the path of the cookie

=head2 domain

Set or Get the domain of the cookie

=head2 expire_cookie

Sets the expiration date of the cookie to 24 hours ago, effectively
removing it from the browser cache.

=head2 _as_string

Returns the string representation of the cookie. The "" operator is
overloaded so if you just 'print $cookie' you should also get the string
representation.

=head1 SEE ALSO

L<NCGI::Query>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Mark Lawrence E<lt>nomad@null.netE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut
