package NCGI::Header;
# ----------------------------------------------------------------------
# Copyright (C) 2005 Mark Lawrence <nomad@null.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# ----------------------------------------------------------------------
# HTTP Header Response object for NCGI
# ----------------------------------------------------------------------
use strict;
use warnings;
use base 'NCGI::Singleton';
use debug;

our $AUTOLOAD;

sub _new_instance {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
        headers      => {content_type => ['text/html']},
        @_,
    };

    debug::log('NCGI::Header Initialised') if(DEBUG);

    bless ($self, $class);
    return $self;
}


sub location {
    my $self = shift;
    delete $self->{headers}->{status};
    $self->{headers}->{location} = [shift];
}

sub _add_location {
    warn 'You cannot _add to the Location header. Use location() instead';
    return;
}

sub AUTOLOAD {
    my $self = shift;
    (my $str = $AUTOLOAD) =~ s/.*:://;

    if ($str =~ /^_add_(.*)/) {
        push(@{$self->{headers}->{lc($1)}}, @_);
    }
    else {
        $self->{headers}->{lc($str)} = [@_];
    }
    return;
}


sub _as_string {
    my $self = shift;
    my @items;
    while (my ($key, $val) = each %{$self->{headers}}) {
        (my $header = $key) =~  s/(^\w)/uc($1)/e;
        $header =~  s/_(\w)/'-' . uc($1)/e;
        foreach (@{$val}) {
            push(@items, "$header: $_");
        }
    }
    return join("\n", @items) . "\n\n";
}


sub _print {
    my $self = shift;
    if ($self->{_is_sent}) {
        warn 'Attempt to send headers more than once';
        return;
    }
    print $self->_as_string();
    $self->{_is_sent} = 1;

    debug::log('Sent HTTP Headers') if(DEBUG);
}


1;
__END__

=head1 NAME

NCGI::Header - HTTP Header object for NCGI

=head1 SYNOPSIS

  use NCGI::Header;
  $header = NCGI::Header->new();
  $header->content_type('text/plain');
  $header->status('200 OK');
  print $header->_as_string();
  # or
  $header->_print();

=head1 DESCRIPTION

B<NCGI::Header> provides a simple HTTP Header object for use
in the Rekudos framework. In most cases Rekudos Module authors will not
need to use this module/object as NCGI::Main creates 
$NCGI::Globals::header for that purpose.

=head1 METHODS

=head2 new( ), new($content_type)

Create a new NCGI::Header object, optionally specifying a content type.

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

Returns a string representation of the HTTP Header.

=head2 $header->_print( )

Print the HTTP header to STDOUT. Exactly the same as
'print $header->_as_string;'.

=head1 SEE ALSO

L<NCGI>

This module was written for the Rekudos framework http://rekudos.net/.

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Mark Lawrence E<lt>nomad@null.netE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut
