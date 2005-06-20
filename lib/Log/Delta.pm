package Log::Delta;
# ----------------------------------------------------------------------
# Copyright (C) 2004,2005 Mark Lawrence <nomad@null.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# ----------------------------------------------------------------------
# Timing/Log object for the Rekudos framework
# ----------------------------------------------------------------------
use strict;
use warnings;
use base 'NCGI::Singleton';
use Time::HiRes qw(time);
use Data::Dumper;

our $AUTOLOAD;


sub _new_instance {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    bless ($self, $class);

    my %args = (
        levels => [],
        @_,
    );

    foreach (@{$args{levels}}) {
        $self->{levels}->{$_} = 1;
    }

    my $mod = __PACKAGE__;

    $self->{start} = time();
    $self->{prev}  = $self->{start};
    $self->{entries} = [];
    ($self->{package}, $self->{filename}, $self->{line}) = caller(1);
    if ($self->{package} =~ /$mod/) {
        ($self->{package}, $self->{filename}, $self->{line}) = caller(2);
    }
    $self->l('Log Initialised', scalar localtime($self->{start}),
              $self->{start});

    return $self;
}


sub age {
    my $self = shift;
    return time - $self->{start};
}


sub AUTOLOAD {
    my $self = shift;
    my $sub  = $AUTOLOAD;
    $sub =~ s/.*:://;
    if ($self->{levels}->{$sub}) {
        ($self->{package}, $self->{filename}, $self->{line}) = caller;
        $self->l(@_);
    }
}


sub l {
    my $self = shift;
    my $now  = time;
    my $str  = '';

    ($self->{package}, $self->{filename}, $self->{line})
        = caller(2) unless($self->{package});

    $self->{package} =~ s/^ModPerl.*/main/;

    my $clock = $now - $self->{start};
    $str .= sprintf "%.5f ", $clock;

    my $delta = $now - $self->{prev};
    $str .= sprintf "(+%.5f)", $delta;

    foreach my $item (@_) {
        if (ref($item)) {
            my $tmp = $Data::Dumper::Indent;
            $Data::Dumper::Indent = 1;
            $str .= ' ' . Dumper($item);
            $Data::Dumper::Indent = $tmp;
        }
        elsif (defined($item)) {
            $str .= ' ' . $item;
        }
        else {
            $str .= ' *undef*';
        }
    }
    $str .= ' (' . $self->{package} .':'. $self->{line} .")";
    push(@{$self->{entries}}, $str);

    $self->{prev} = $now;
    $self->{package} = $self->{filename} = $self->{line} = undef;

    print STDERR $str,"\n";
}


sub as_string {
    my $self = shift;
    return join("\n", @{$self->{entries}});
}


sub delete {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    no strict 'refs';
    my $instance = \${ "$class\::_instance" };
    undef $$instance;
}


#DESTROY {
#    my $self = shift;
##    ($self->{package}, $self->{filename}, $self->{line}) = caller(1);
#    $self->l('Log Destroyed');
#}


1;
__END__

=head1 NAME

Log::Delta - Logging object with timing and caller information

=head1 SYNOPSIS

  use Log::Delta;
  my $log = Log::Delta->new();
  $log->l('A log message');
  print $log->as_string();

Will produce the following output:

  0.00000 (+0.00000) Log Init at 1112962701.93193
  0.00006 (+0.00006) main:3 A log message

=head1 DESCRIPTION

B<Log::Delta> is a simple Log utility with hi-resolution timing. It is
suitable for basic performance analysis.

=head1 METHODS

=head2 new( )

Create a new Log::Delta object.

=head2 l($message)

Add an entry to the log with the current time as specified by Time::HiRes.

=head2 as_string( )

Print all entries in the log ordered by time. The first column specifies
how many seconds after log creation the entry was added. The second
column specifies how long between the current entry and the previous one.

=head1 REQUIRES

L<Time::HiRes>

=head1 SEE ALSO

This module was written for the Rekudos framework: http://rekudos.net/

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004,2005 Mark Lawrence E<lt>nomad@null.netE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut
