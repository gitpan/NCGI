package NCGI::Response::Header;
use strict;
use warnings;
use Carp;

our $VERSION = '0.10';
our $AUTOLOAD;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my $self  = {
        headers => {},
        @_,
    };

    bless ($self, $class);
    return $self;
}


sub location {
    my $self = shift;
    delete $self->{headers}->{status};
    $self->{headers}->{location} = [shift];
}

sub _add_location {
    croak 'You cannot _add to the Location header. Use location() instead';
}

sub AUTOLOAD {
    my $self = shift;
    (my $str = $AUTOLOAD) =~ s/.*:://;


    for (@_) {
        carp "undefined value for header '$str'" if (!defined($_));
    }

    if ($str =~ /^_add_(.*)/) {
        push(@{$self->{headers}->{lc($1)}}, @_);
    }
    elsif ($str !~ /[a-zA-Z]+[a-zA-Z-]+/) {
        croak 'unknown function '.__PACKAGE__."::$str";
    }
    else {
        $self->{headers}->{lc($str)} = [@_];
    }
    return;
}


sub _as_string {
    my $self = shift;
    my @items;

    if ($ENV{SERVER_SOFTWARE} &&
        $ENV{SERVER_SOFTWARE} =~ m/^HTTP::Server::Simple/) {
        if ($self->{headers}->{status}) {
            push(@items, 'HTTP/1.1 '. $self->{headers}->{status}->[0]);
        }
        else {
            push(@items, 'HTTP/1.1 200 OK');
        }
    }
    while (my ($key, $val) = each %{$self->{headers}}) {
        (my $header = $key) =~  s/(^\w)/uc($1)/e;
        $header =~  s/_(\w)/'-' . uc($1)/e;
        foreach (@{$val}) {
            push(@items, "$header: $_");
        }
    }
    return join("\n", @items) . "\n\n";
}


sub _send {
    my $self = shift;
    if ($self->{sent}) {
        croak 'Cannot send headers more than once';
    }
    if (!exists($self->{headers}->{status})) {
        $self->{headers}->{status}->[0] = '200 OK';
    }
    print $self->_as_string();
    $self->{sent} = 1;
}


sub _print {
    croak '_print is obsolete - use _send instead';
}


1;
__END__

=head1 NAME

NCGI::Response::Header - HTTP Header object for NCGI

=head1 SYNOPSIS

  use NCGI::Response::Header;
  my $header = NCGI::Response::Header->new();

  $header->content_type('text/plain');
  $header->status('200 OK');
  $header->test_header('tested');
  $header->_add_multi('1');
  $header->_add_multi('2');
  $header->_send();

  print "The header sent was:\n\n",$header->_as_string();

  # The header sent was:
  #
  # Content-Type: text/plain
  # Status: 200 OK
  # Multi: 1
  # Multi: 2
  # Test-Header: tested

=head1 DESCRIPTION

B<NCGI::Response::Header> provides a simple HTTP Header object for responding
to CGI requests.

=head1 METHODS

=head2 new

Returns a new NCGI::Response::Header object.

=head2 location

Adds a 'Location:' header, making sure that there is no 'Status:' header
as well.

=head2 header_type

Create/Set the header 'Header-Type'. Notice that underlines are converted
to dashes and that the first character of words are uppercased. This
is an AUTOLOAD function meaning you can create whatever headers you like.
If there were previously multiple 'Header-Type' headers then they are
all replaced by the value of this call.

There is no validity checking when setting so you should read the HTTP/MIME
specifications for valid strings.

=head2 _add_header_type

Add a header 'Header-Type'. This can be called multiple times and multiple
headers will be sent.  Notice the automatic formatting as is done
for header_type.

=head2 _as_string

Returns a string representation of the HTTP Header.

=head2 _send

Print the HTTP header to STDOUT. Exactly the same as
'print $header->_as_string;' except that B<_send> keeps track if it
has already been called and will croak if called more than once.

=head1 SEE ALSO

L<NCGI>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2008 Mark Lawrence E<lt>nomad@null.netE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut
