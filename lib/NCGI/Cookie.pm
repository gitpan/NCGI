package NCGI::Cookie;
use strict;
use warnings;
use Carp;
use Digest::MD5 qw(md5_hex);
use CGI::Util qw(escape unescape);
use overload '""' => \&_as_string, 'fallback' => 1;

our $VERSION = '0.07';

# ----------------------------------------------------------------------
# Class Functions
# ----------------------------------------------------------------------

#
# Return a HASHREF of Cookies recieved
#
sub fetch {
    my @pairs = split(/\;\s*/, $ENV{HTTP_COOKIE} ? $ENV{HTTP_COOKIE} : '');
    my $hashref = {};
    foreach my $sets (@pairs) {
        my ($key,$val) = split(/=/, $sets);
        if (exists($hashref->{unescape($key)})) {
            if (ref($hashref->{unescape($key)}) eq 'ARRAY') {
                push(@{$hashref->{unescape($key)}}, unescape($val));
            }
            else {
                push(@{$hashref->{unescape($key)}},
                       $hashref->{unescape($key)}, unescape($val));
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

    $self->{name}  = escape(_cookie_scrub($self->{name}));
    $self->{value} = $self->{value} ? escape(_cookie_scrub($self->{value})) :
                     md5_hex(md5_hex(time . {} . rand() . $$));

    $self->{expires} = 60 * $self->{expires};
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
    $str   .= ' expires=' . _cookie_date($self->{expires}) . ';' 
                                                 if ($self->{expires});
    $str   .= ' path=' . $self->{path} .';'      if ($self->{path});
    $str   .= ' domain=' . $self->{domain} . ';' if ($self->{domain});
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
  $str =~ s/(\;|\=)//g;
  return $str;
}


#
# this routine accepts the number of seconds to add to the server
# time to calculate the expiration string for the cookie. Cookie
# time is ALWAYS GMT!
#
sub _cookie_date() {

  my ($seconds) = @_;

  my %mn = ('Jan','01', 'Feb','02', 'Mar','03', 'Apr','04',
            'May','05', 'Jun','06', 'Jul','07', 'Aug','08',
            'Sep','09', 'Oct','10', 'Nov','11', 'Dec','12' );
  my $sydate=gmtime(time + $seconds);
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

NCGI::Cookie - HTTP Cookie object for NCGI

=head1 SYNOPSIS

  use NCGI::Cookie;

  # subroutine for reading cookies from the query
  my $hashref      = NCGI::Cookie::fetch();
  my $cookie_value = $hashref->{cookie_name};

  # object methods for creating cookies to send in the response
  my ($name, $value, $min, $path, $domain) = ('c1','value',60,'/',undef);
  my $c = NCGI::Cookie->new(
    name    => $name,
    value   => $value,
    expires => $min,
    path    => $path,
    domain  => $domain,
  );

  # You can also "print $c->_as_string;"
  print $c; # c1=value; expires=Tue 07-Jun-2005 12:02:01 GMT; path=/;


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

Set or Get the expiration value of the cookie in minutes

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
