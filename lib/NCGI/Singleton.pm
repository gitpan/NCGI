package NCGI::Singleton;
# ----------------------------------------------------------------------
# Copyright (C) 2005 Mark Lawrence <nomad@null.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# ----------------------------------------------------------------------
# Singleton object for NCGI
# ----------------------------------------------------------------------
use strict;
use warnings;
use debug;

our $VERSION = '0.01';

sub instance {
    my $class  = shift;

    # get a reference to the _instance variable in the $class package
    no strict 'refs';
    my $instance = \${ "$class\::_instance" };
    return $$instance if ($ENV{"NCGI_SINGLETON_$class"});

    debug::log("$class->_new_instance ",caller) if(DEBUG);
    $$instance = $class->_new_instance(@_);
    $ENV{"NCGI_SINGLETON_$class"} = join(' ', caller);
    return $$instance;
};


1;
__END__

=head1 NAME

NCGI::Singleton - Singleton object for NCGI

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
