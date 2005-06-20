
package debug;

use strict;
use warnings;

our $VERSION = '0.02';

sub import {
    shift;
    my @packages = @_;
	# turn off strict refs 
	# 	cause we are messing with stuff
	# and turn off warnings for redefine 
	# 	cause we are redefining
	no strict 'refs'; 
	no warnings 'redefine';
	# are we turning the debugger on? 
	# (meaning, have any package names been passed in)
	if (@packages) {
		# turn DEBUG on for each class in the package list
    	*{"${_}::DEBUG"} = sub { 1 } foreach @packages;
	}
	else {
		# either that we are just registering 
		# the module as debuggable, so we 
		# need to find out the calling package
		# so that we can make a null DEBUG
		# subroutine
		my ($calling_package) = caller();
		*{"${calling_package}::DEBUG"} = sub { 0 };
		*{"${calling_package}::Dumper"} = sub {
            eval { require Data::Dumper };
            return Data::Dumper::Dumper(@_) unless $@;
            };
	}
}


sub on {
    shift if $_[0] eq __PACKAGE__;
    my @packages = @_;
	# turn off strict refs 
	# 	cause we are messing with stuff
	# and turn off warnings for redefine 
	# 	cause we are redefining
	no strict 'refs'; 
	no warnings 'redefine';
	*{"${_}::DEBUG"} = sub { 1 } foreach @packages;	
}

sub off {
    shift if $_[0] eq __PACKAGE__;
    my @packages = @_;
	# turn off strict refs 
	# 	cause we are messing with stuff
	# and turn off warnings for redefine 
	# 	cause we are redefining
	no strict 'refs'; 
	no warnings 'redefine';
	*{"${_}::DEBUG"} = sub { 0 } foreach @packages;	
}

# methods to inspect modules with

sub is_debug_on {
    shift if $_[0] eq __PACKAGE__;
    my $package = shift;
	# this checks to see if debug is 
	# on my returning the value of debug
	# for that package, convient isnt it :)
	no strict 'refs'; 
	return 0 unless defined &{"${package}::DEBUG"};
	return &{"${package}::DEBUG"}();	
}


# Debug Log Filters
# --------------------------------
# this is a private hash
# of package -> to -> filter mappings
# so that every package can have its own 
# debugging filter.

# hash of filters for packages
my $log_filters = {
    __DEFAULT__ => sub { print STDERR "debug->log + ", @_, "\n" }
    };

# this function is essentially a dispatcher
# for the log filter table above
sub log { 
    shift if $_[0] eq __PACKAGE__;
    # the filter key is the name of the calling package
    my ($log_filter_key) = caller();
    # if a specialized filter does not exist for the package 
    # then  the default one is used
    $log_filter_key = "__DEFAULT__" unless exists ${$log_filters}{$log_filter_key};
    # the filter is then executed on the arguments to this function
    $log_filters->{$log_filter_key}->(@_);
}

# this allows for the setting of 
# a log filter for a specific package
sub set_log_filter { 
    shift if $_[0] eq __PACKAGE__;
    my ($package, $filter) = @_;
    (ref($filter) eq "CODE") 
        || die "debug module exception: the filter must be a subroutine reference";
    # if all is okay then put it in the hash
    $log_filters->{$package} = $filter;
}

# setting the default log filter for all
sub set_default_log_filter {
    shift if $_[0] eq __PACKAGE__;
    my ($filter) = @_;
    (ref($filter) eq "CODE") 
        || die "debug module exception: the filter must be a subroutine reference";
    $log_filters->{__DEFAULT__} = $filter;		
}

# this allows you to remove a filter 
# entirely if you want
sub remove_log_filter {
    shift if $_[0] eq __PACKAGE__;
    my $package = shift;
    # delete it if it exists
    delete $log_filters->{$package} if exists ${$log_filters}{$package};
}

1;

__END__

=head1 NAME

debug - Perl pragma for debugging and logging of debug lines.

=head1 SYNOPSIS

  package Foo;
  # start by embedding calls to 
  # debug::log inside your module
  # of package.
  
  # use the pragma
  use debug;
  
  sub bar {
    # call debug::log if you have
    # something to say, but don't
    # forget "if DEBUG"  
    debug::log("entering Foo::bar") if DEBUG;
    print "foo";
    # you can also call it with the
    # object '->' syntax if you like.
    debug->log("leaving Foo::bar") if DEBUG;
  }
  
  1;

  # then in your main script, you 
  # can do one of the following things
  
  # use your module
  use Foo;  
  
  # turn debug on for the Foo package (at compile-time)
  use debug qw(Foo);
  
  # you can also do it this way (at run-time)
  debug->on("Foo");
  
  # now comes your code ...
  
  Foo::bar();

  # your would then look like this:
  debug-log + entering Foo::bar
  foo
  debug-log + leaving Foo::bar

=head1 DESCRIPTION

The B<debug> pragma provides a very simple way of turning on and off your debugging lines, as well as a very flexible way of logging those lines to literally anywhere you want.

=head2 Register Your Module

You need to register a module for debugging by placing C<use debug> at the top of you module. Then you can embed calls to C<debug::log> within your code making sure to surround them with conditional checks for the value of the C<DEBUG> constant. See the SYNOPSIS section for an example. After that you can turn the debugging on and off from any other module or namespace. You can do this one of 2 ways:

  # compile-time way
  use debug qw(Foo Bar Baz); # add as many modules as you like 
  
  # run-time way
  debug->on qw(Foo Bar Baz); # add as many modules as you like
  
=head2 Debug Log Filters

Now comes the debug log filters. If you do nothing else, your debug lines will look like the example in the SYNOPSIS section. But you can change that very easily. By changing the default log filter with (what else) the C<set_default_log_filter> function. Here is an example:

  debug::set_default_log_filter(sub { print STDERR "debugging : ", @_ });

This will send all the C<debug::log> calls to STDERR and prepend the string "debugging : " to them all. Any anyonomous subroutine or subroutine reference will do.  

But the default filter is not the only one you can change, you can also assign a specific filter for each package you are debugging. Here is an example:

  debug::set_log_filter(Foo => sub { print "Debugging Foo >> ", @_ });

This log filter will only be called from the C<Foo> package. And just as you can add them, you can take them away. Use the C<remove_log_filter> function. Again, an example:

  debug::remove_log_filter("Foo");

All C<debug::log> calls in Foo will now go through the default log filter again.

=head2 More Complex Filter Examples

A debug log filter which prints the name of package it was called in.

  sub my_calling_package_filter {
    print "debugging -> ", (caller(1))[0], " : ", @_, "\n";	
  }
  
  debug->set_log_filter(Foo => \&my_calling_package_filter);

A debug log filter to convert things to HTML.

  sub my_HTML_log_filter {
    # first we need to join the arguements into a single string
    my $output = join "" => @_;
    # then we replace any \n (newlines) with an HTML <BR> tag
    $output =~ s/\n/\<BR\>/g;
    # then we replace any tabs with 4 "&nbsp;"s
    $output =~ s/\t/\&nbsp\;\&nbsp\;\&nbsp\;\&nbsp\;/g;
    # then we wrap the output in <P> tags and return it
    return "<P>$output</P>";
  }
    
  debug->set_log_filter(Foo => \&my_HTML_log_filter);

A debug log filter which will print a basic date stamp.

  debug->set_log_filter(Foo => sub { "[" . localtime() . "]: ", @_  } );
  
Here is a filter which appends to a file.

  sub append_to_file {
      open LOG, ">>", "/tmp/debug.log";
      print LOG "debug->log : ", @_;
      close LOG;
  }
  
  debug->set_log_filter(Foo => \&append_to_file);

=head1 FUNCTIONS

=over 4

=item B<on (@packages)>

This will turn debugging on for all the packages given in the C<@packages> arguement.

=item B<off (@packages)>

This will turn debugging off for all the packages given in the C<@packages> arguement.

=item B<is_debug_on ($packages)>

This will return true (1) if debugging is on for that module and false (0) otherwise.

=item B<log (@statements)>

An array of strings and variables (C<@statements>) which will be logged. These values are fead through either the current default log filter or the one assigned specifically to the current package.

=item B<set_default_log_filter ($log_filter)>

The C<$log_filter> argument is expected to be a subroutine reference, and if it is not, an exception is thrown. For information about how to create the log filters see the above sections.

=item B<set_log_filter ($package, $log_filter)>

This assigns a specific C<$log_filter> to a particular C<$package>, from then on all C<debug->log()> calls from within that package will go through this filter. The C<$log_filter> argument is expected to be a subroutine reference, and if it is not, an exception is thrown. For information about how to create the log filters see the above sections.

=item B<remove_log_filter ($package)>

This will remove the log filter for the specific C<$package>, thereby returning it to using the default log filter.

=back

=head1 EXPORTS

This module exports two functions:

=over 4

=item B<DEBUG>

This is just a boolean flag, so that you can write:

  debug->log("This line should work") if DEBUG;

=item B<Dumper>

This is a lazily loaded C<Data::Dumper::Dumper> wrapper. Why? Well, to start with, someone suggested it to me (see L<ACKNOWLEDGEMENTS>), and secondly I realized how many times I have done this:

  use Data::Dumper;
  debug->log(Dumper(\%strucutre)) if DEBUG;

And how much nicer it would be if I could do this:

  debug->log(Dumper(\%strucutre)) if DEBUG;

The reason we lazily load L<Data::Dumper> is that it will take up a lot of memory, so we don't load it unless we absolutely have to. If you do not have L<Data::Dumper> installed (for some strange reason), this function will basically return undef.

=back

=head1 BUGS

None that I am aware of. Of course, if you find a bug, let me know, and I will be sure to fix it. This module has been used in several production sites for over 2 years now without incident, the code released here has only been slightly modified, and documentation and tests added.

=head1 CODE COVERAGE

I use B<Devel::Cover> to test the code coverage of my tests, below is the B<Devel::Cover> report on this module test suite.

 ------------------------ ------ ------ ------ ------ ------ ------ ------
 File                       stmt branch   cond    sub    pod   time  total
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 debug.pm                  100.0   96.4    n/a  100.0  100.0  100.0   99.3
 ------------------------ ------ ------ ------ ------ ------ ------ ------
 Total                     100.0   96.4    n/a  100.0  100.0  100.0   99.3
 ------------------------ ------ ------ ------ ------ ------ ------ ------

=head1 A NOTE ABOUT NAMING

This module uses an all lowercase name, which is considered "wrong" by the perl-5-porters group. The idea is that all lowercase names are reserved for pragmas I<they> create and which implement functionality missing in perl itself. I can understand their logic, and do not think that they are in the wrong in that stance. However, I do prefer to name my pragmas with lowercase names as well. That all said, I am making the choice to keep the lowercase name, and it is your choice as the user whether you want to use my module or not. I may be forcing my module to a life of obscurity by doing this, but so be it.

=head1 SEE ALSO

This module provides a simple flexible and lightweight means of logging your debug calls. If you have more sophisticated debugging/logging needs I suggest you look at L<Log::Log4Perl>. While I have never used it myself, I have heard many good things about it. 

=head1 ACKNOWLEDGEMENTS

=over 4

=item Thanks to Terrence Brannon (metaperl) for suggesting the lazily loaded C<Data::Dumper::Dumper> trick.

=back

=head1 AUTHOR

stevan little, E<lt>stevan@iinteractive.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004, 2005 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
