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

our $VERSION = '0.01';
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
  my $header = NCGI::Header->instance();

  $header->content_type('text/plain');
  $header->status('200 OK');
  $header->test_header('tested');
  $header->_add_multi('1');
  $header->_add_multi('2');
  $header->_print();

  print "The header sent was:\n\n",$header->_as_string();

  # The header sent was:
  #
  # Content-Type: text/plain
  # Status: 200 OK
  # Multi: 1
  # Multi: 2
  # Test-Header: tested

=head1 DESCRIPTION

B<NCGI::Header> provides a simple HTTP Header object for responding
to CGI requests. It is a singleton object (see L<Class::Singleton> on
CPAN for a description of what this means).

=head1 METHODS

=head2 instance()

Returns a reference to the NCGI::Header object, creating it if necessary.
The newly created object has a single header 'Content-Type' set to
'text/html'.

=head2 header_type()

Create/Set the header 'Header-Type'. Notice that underlines are converted
to dashes and that the first character of words are uppercased. This
is an AUTOLOAD function meaning you can create whatever headers you like.
If there were previously multiple 'Header-Type' headers then they are
all replaced by the value of this call.

There is no validity checking when setting so you should read the HTTP/MIME
specifications for valid strings.

=head2 _add_header_type()

Add a header 'Header-Type'. This can be called multiple times and multiple
headers will be sent.  Notice the automatic formatting as is done
for header_type.

=head2 _as_string()

Returns a string representation of the HTTP Header.

=head2 _print()

Print the HTTP header to STDOUT. Exactly the same as
'print $header->_as_string;' except that B<_print> will warn if it is called
more than once.

=head1 SEE ALSO

L<NCGI::Singleton>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Mark Lawrence E<lt>nomad@null.netE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut
