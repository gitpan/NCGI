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
use base 'Class::Singleton';
use NCGI::Cookie;

our $VERSION = '0.01';

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    no strict 'refs';
    my $instance = \${ "$class\::_instance" };
    undef $$instance;
    return $class->instance(@_);
}

#
# This only gets called from the first Class::Singleton::instance() call
#
sub _new_instance {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
        debug => 0,
        @_,
    };

    $self->{q_query} = {};
    $self->{q_full}  = '';
    $self->{q_type}  = 'NOQUERY';

    if ($ENV{CONTENT_LENGTH}) {
        $self->{q_type}  = 'POST';
        if (!defined(read(STDIN, $self->{q_full}, $ENV{CONTENT_LENGTH}))) {
            warn "Could not read from STDIN: $!";
            return undef;
        }
    }
    elsif ($ENV{QUERY_STRING}) {
        $self->{q_type} = 'GET';
        $self->{q_full} = $ENV{QUERY_STRING};
    }
    chomp($self->{q_full});

    $self->{q_query} = {};
    foreach (split(/[&;]/, $self->{q_full})) {
        my ($key, $val) = split('=', $_, 2);
        $self->{q_query}->{unescape($key)} = unescape($val);
    }

    $self->{q_cookies} = NCGI::Cookie::fetch();

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

sub query {
    my $self = shift;
    return $self->{q_query};
}

sub full_query {
    my $self = shift;
    return $self->{q_full};
}

sub cookie {
    my $self = shift;
    return $self->{q_cookie};
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
