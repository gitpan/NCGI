package NCGI::Query;
# ----------------------------------------------------------------------
# Copyright (C) 2005 Mark Lawrence <nomad@null.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# ----------------------------------------------------------------------
# HTTP GET/POST Query object for NCGI
# ----------------------------------------------------------------------
use strict;
use warnings;
use base 'NCGI::Singleton';
use NCGI::Cookie;
use CGI::Util qw(unescape);
use debug;

our $VERSION = '0.01';

#
# This only gets called from the first Class::Singleton::instance() call
#
sub _new_instance {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
        @_,
    };

    $self->{q_params} = {};
    $self->{q_full}   = '';
    $self->{q_type}   = 'NOQUERY';


    if ($ENV{CONTENT_LENGTH}) {
        $self->{q_type}  = 'POST';
        my $length = read(STDIN, $self->{q_full}, $ENV{CONTENT_LENGTH});
        if (!defined($length) or $length != $ENV{CONTENT_LENGTH}) {
            warn "Could not read from STDIN: $!";
            return undef;
        }
    }
    elsif ($ENV{QUERY_STRING}) {
        $self->{q_type} = 'GET';
        $self->{q_full} = $ENV{QUERY_STRING};
    }
    chomp($self->{q_full});

    $self->{q_params} = {};
    foreach (split(/[&;]/, $self->{q_full})) {
        my ($key, $val) = split('=', $_, 2);
        $self->{q_params}->{unescape($key)} = unescape($val);
    }

    $self->{q_cookies} = NCGI::Cookie::fetch();

    debug::log('NCGI::Query Initialised with '. $self->{q_type}) if(DEBUG);

    bless ($self, $class);
    return $self;
}

sub isquery {
    my $self = shift;
    return ($self->{q_type} ne 'NOQUERY');
}

sub isget {
    my $self = shift;
    return ($self->{q_type} eq 'GET');
}

sub ispost {
    my $self = shift;
    return ($self->{q_type} eq 'POST');
}

sub param {
    my $self = shift;
    my $param = shift;
    exists($self->{q_params}->{$param}) && return $self->{q_params}->{$param};
    return undef;
}

sub params {
    my $self = shift;
    return $self->{q_params};
}

sub full_query {
    my $self = shift;
    return $self->{q_full};
}

sub cookie {
    my $self = shift;
    my $param = shift;
    exists($self->{q_cookies}->{$param}) && return $self->{q_cookies}->{$param};
    return undef;
}

sub cookies {
    my $self = shift;
    return $self->{q_cookies};
}

sub dump_params {
    my $self = shift;
    my $str = '';
    while (my ($key, $val) = each %{$self->{q_params}}) {
        $val = '******' if ($key =~ /pass/);
        $str .= "$key = $val\n";
    }
    return $str;
}

sub dump_cookies {
    my $self = shift;
    my $str;
    while (my ($key, $val) = each %{$self->{q_cookies}}) {
        $str .= "$key = $val\n";
    }
    return $str;
}

1;
__END__

=head1 NAME

NCGI::Query - HTTP GET/POST Query object for NCGI

=head1 SYNOPSIS

  use NCGI::Query;
  my $q = NCGI::Query->new();

  if ($q->isquery) {
    print "GET\n" if $q->isget();
    print "POST\n" if $q->isget();
    print "Your submit button is called: ",$q->query->{'submit'};
  }

=head1 DESCRIPTION

B<NCGI::Query> provides a simple HTTP Query object for use
in the Rekudos framework. In most cases Rekudos Module authors will not
need to use this module/object as NCGI::Main creates 
$NCGI::Globals::header for that purpose.

=head1 METHODS

=head2 new( ), new($content_type)

Create a new NCGI::Query object, optionally specifying a content type.

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

Returns a string representation of the HTTP Query.

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
