package NCGI::Singleton;
use strict;
use warnings;
our $VERSION = '0.09';

sub instance {
    my $class  = shift;

    # get a reference to the _instance variable in the $class package
    no strict 'refs';
    my $instance = \${ "$class\::_instance" };
    return $$instance if ($ENV{"NCGI_SINGLETON_$class"});

    my $tmp = $class->_new_instance(@_);
    if (ref($tmp)) {
        $$instance = $tmp;
        $ENV{"NCGI_SINGLETON_$class"} = join(' ', caller);
        return $$instance;
    }
}


sub _reset_instance {
    my $class  = shift;
    # get a reference to the _instance variable in the $class package
    no strict 'refs';
    my $instance = \${ "$class\::_instance" };

    $$instance = $class->_new_instance(@_);
    $ENV{"NCGI_SINGLETON_$class"} = join(' ', caller);
    return $$instance;
};


1;
__END__

=head1 NAME

NCGI::Singleton - Singleton object for persistent CGI environments

=head1 SYNOPSIS

  # In your package
  package MyPackage;
  use base 'NCGI::Singleton';

  # In scripts, other modules, wherever
  use MyPackage;
  my $obj = MyPackage->instance();

=head1 DESCRIPTION

B<NCGI::Singleton> is an implementation of L<Class::Singleton> that works
in persistent Perl environments such as mod_perl and SpeedyCGI. It
is drop-in-replaceable with L<Class::Singleton> so nothing else is
documented here.

The reason L<Class::Singleton> doesn't work (as I would like it to)
is because it relies on the existence of a global variable in a package.
Since globals are not deleted for each CGI request it is not easy to
have singletons that only exist for the length of a CGI request.

=head1 METHODS

=head2 instance

Returns the singleton, creating it if it doesn't already exist.

=head1 SEE ALSO

L<Class::Singleton>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 Mark Lawrence E<lt>nomad@null.netE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut
