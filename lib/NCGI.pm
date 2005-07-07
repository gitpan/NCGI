package NCGI;
# ----------------------------------------------------------------------
# Copyright (C) 2005 Mark Lawrence <nomad@null.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# ----------------------------------------------------------------------
# NCGI - A New CGI Module
# ----------------------------------------------------------------------
use 5.006;
use strict;
use warnings;
use base 'NCGI::Query';
use Carp;
use NCGI::Header;
use XML::API;
use debug;

our $VERSION = '0.03';


# ----------------------------------------------------------------------
# This method is not even private - it is only called by NCGI::Query
# which is derived from NCGI::Singleton
# ----------------------------------------------------------------------
sub _new_instance {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %args = (
        on_warn => \&warn,
        on_die  => \&die,
        @_,
    );

    my $self = NCGI::Query->instance(%args);
    bless($self, $class);

    #
    # These two should usually never fail (or produce warnings) and
    # we need them to be here before we reset __DIE__ and __WARN__
    #
    $self->{cgi_header}  = NCGI::Header->instance();
    $self->{cgi_content} = XML::API->new(doctype => 'xhtml');

    debug::log('Created XML::API Object') if(DEBUG);

    $self->{old_warn} = $main::SIG{__WARN__};
    if (ref($self->{on_warn}) eq 'CODE') {
        $main::SIG{__WARN__} = $self->{on_warn};
        debug::log('__WARN__ Handler installed') if(DEBUG);
    }

    $self->{old_die}  = $main::SIG{__DIE__};
    if (ref($self->{on_die}) eq 'CODE') {
        $main::SIG{__DIE__} = $self->{on_die};
        debug::log('__DIE__ Handler installed') if(DEBUG);
    }

    my $html = $self->{cgi_content};

    $html->head_open();
    $html->_set_id('head');
    $html->head_close();

    $html->body_open();
    $html->_set_id('body');

    $self->{cgi_sent} = 0;

    debug::log('NCGI Object Initialised') if(DEBUG);

    return $self;
}

# ----------------------------------------------------------------------
# Public methods
# ----------------------------------------------------------------------


#
# A shortcut for NCGI::Header->instance
#
sub header {
    my $self = shift;
    return $self->{cgi_header};
}


#
# A getter/setter for the content of this response
#
sub content {
    my $self = shift;
    $self->{cgi_content} = shift if(@_);
    return $self->{cgi_content};
}


#
# Send the header and content to the client
#
sub respond {
    my $self = shift;
    my $html = $self->{cgi_content};

    if ($self->{cgi_sent}) {
        carp 'Attempt to respond() more than once';
        return;
    }

    ### DEBUG ###
    debug::log('Sending response to client at',(caller)[1,2]) if(DEBUG);
    $html->_goto('body') if(DEBUG);
    require Log::Delta   if(DEBUG);
    $html->pre(Log::Delta->instance->as_string) if(DEBUG);
    ### DEBUG ###

    #
    # From here on it doesn't make sense for us to handle
    # warn and die
    #
    $main::SIG{__WARN__} = $self->{old_warn};
    $main::SIG{__DIE__}  = $self->{old_die};

    $self->{cgi_header}->_print();
    $html->_print();
    $self->{cgi_sent} = 1;
}


#
# A handler to override 'warn' calls
#
sub warn {
    my $self = __PACKAGE__->instance();
    if ($self->{cgi_sent}) {
        warn @_;
        return;
    }

    my $html    = $self->{cgi_content};
    my $current = $html->_current();
    $html->_goto('body');
    $html->pre_open({style => 'color: #cc0000;'}, 'warning: ');

    (my @tmp = @_) =~ s/\n//mg;
    foreach (@_) {
        (my $x = $_) =~ s/\n$//g;
        $html->_add($x);
        debug::log('warn:', $x) if(DEBUG);
    }

    $html->pre_close();
    $html->_goto($current);

    return;
}


#
# A handler to override 'die' signals
#
sub die {
    my $self = __PACKAGE__->instance();
    if ($self->{cgi_sent}) {
        die @_;
    }


    #
    # First of all check if this occured within an "eval" block and
    # don't actually die if that is the case
    #
    my $i = 1;
    while (my @caller = caller($i)) {
        if ($caller[3] =~ /^\(?eval\)?$/) {
            debug::log('die (eval):', @_) if(DEBUG);
            return;
        }
        $i++;
    }

    #
    # respond() if the output has not already been sent
    #

    debug::log('die:', @_) if(DEBUG);
    if ($self->{cgi_sent}) {
        die "'die' was called after browser output sent, with: @_";
    }

    $self->{cgi_header}->status('500 Internal Server Error');

    my $html = $self->{cgi_content};
    $html->_goto('body');
    $html->pre({style => 'color: #ff0000;'}, 'error: ', @_);
    $html->pre('500 Internal Server Error');
    $self->respond();
    die @_;
}



1;
__END__

=head1 NAME

NCGI - A Common Gateway Interface (CGI) Class

=head1 SYNOPSIS

  use NCGI;
  my $cgi  = NCGI->instance();
  my $html = $cgi->content;

  $html->_goto('head');
  $html->title('A Simple Example');

  $html->_goto('body');
  $html->h1('Simple Form');

  $html->form_open();
  $html->_add("What's your name? ");
  $html->input({type => 'text', name => 'name'});
  $html->input({type => 'submit', name => 'submit', value => 'Submit'});

  $html->form_close();
  $html->hr();

  if ($cgi->params{submit}) {
    $html->p('I think your name is ', $cgi->params{name});
  }

  $cgi->respond();

=head1 DESCRIPTION

B<NCGI> has the same basic function as the well known L<CGI> module.
It is an aide for authors writing CGI scripts. The advantages over CGI
are

 * Smaller Codebase
 * Modular Codebase: separate Header, XHTML, Query Classes
 * XML::API based for better output
 * Easy debugging features built-in
 * Different API

The disadvantages over CGI are

 * Different API
 * Less features
 * Probably not as portable

=head1 METHODS

As B<NCGI> derives from L<NCGI::Query> please see the L<NCGI::Query>
documentation for base methods.

=head2 instance( ... )

NCGI is a Singleton class. See L<Class::Singleton> on CPAN for details on
what this means. The B<instance> function returns a reference to the singleton,
creating it if necessary and accepting the following parameters:

=head3 on_warn

By default the Perl 'warn' function is overridden to include the warnings
in the html response. If you want to turn this off you should set on_warn
to 'undef'.

=head3 on_die

By default the Perl 'die' function is overridden to include the die
arguments in the html response. If you want to turn this off you should
set on_die to 'undef'.

=head2 header()

Returns the NCGI::Header object for this response

=head2 content()

Get/Set the content for the response to the user agent. This must be
an object that supplies at a mimimum a B<_print> method. By default
this is an L<XML::API> object with 'head' and 'body' elements already
created.

=head2 respond()

Sends the header and the content back to the user agent. Will complain
if called more than once.

=head1 SEE ALSO

L<NCGI::Singleton>, L<NCGI::Header>, L<NCGI::Query>, L<XML::API>, L<debug>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut

