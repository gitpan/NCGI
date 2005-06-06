package NCGI;
# ----------------------------------------------------------------------
# Copyright (C) 2005 Mark Lawrence <nomad@null.net>
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
# ----------------------------------------------------------------------
# NCGI - A New CGI
# ----------------------------------------------------------------------
use 5.006;
use strict;
use warnings;
use base qw(NCGI::Query);
use Carp;
use XML::API;
use NCGI::Header;
use rek::Log;

our $VERSION = '0.01';
our $html;

#
# This only gets called from the first Class::Singleton::instance() call
#
sub _new_instance {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    my %args = (
        debug => 0,
        @_,
    );

    my $self = NCGI::Query->new(@_);

    $self->{cgi_on_die}  = \&die;
    $self->{cgi_on_warn} = \&warn;
    $self->{cgi_debug}   = $args{debug};

    if (ref($self->{cgi_on_die}) eq 'CODE') {
        $main::SIG{__DIE__} = $self->{cgi_on_die};
    }
    if (ref($self->{cgi_on_warn}) eq 'CODE') {
        $main::SIG{__WARN__} = $self->{cgi_on_warn};
    }

    $self->{cgi_header} = NCGI::Header->new();
    $self->{cgi_html}   = XML::API->new(doctype => 'xhtml');
    $self->{cgi_sent}   = 0;

    $html = $self->{cgi_html};

    if ($self->{debug}) {
        $self->{'log'} = rek::Log->instance();
        $self->{'log'}->l('NCGI Created');
    }

    $html->head_open();
    $html->_set_id('head');
    $html->head_close();

    $html->body_open();
    $html->_set_id('body');

    $self->{cgi_header}->status('200 OK');
    bless($self, $class);
    return $self;
}

sub header {
    my $self = shift;
    return $self->{cgi_header};
}


sub html {
    my $self = shift;
    $self->{cgi_html} = shift if(@_);
    return $self->{cgi_html};
}

sub send {
    my $self = shift;
    $self->respond(@_);
}

sub respond {
    my $self = shift;
    if ($self->{cgi_sent}) {
        carp 'Attempt to respond() more than once';
        return;
    }
    if ($self->{debug} == 2) {
        $html->_goto('body');
        $html->pre($self->{'log'}->as_string);
    }
    $self->{cgi_header}->_print();
    $html->_print();
    $self->{cgi_sent} = 1;
}

#
# A default handler in the event that 'warn' gets called
#
sub warn {
    my $self = __PACKAGE__->instance();

    my $current = $html->_current();
    $html->_goto('body');
    $html->pre_open({style => 'color: #cc0000;'}, 'warning: ');

    (my @tmp = @_) =~ s/\n//mg;
    foreach (@_) {
        (my $x = $_) =~ s/\n$//g;
        $html->_add($x);
        if ($self->{debug}) {
            $self->{'log'}->l('warn:', $x);
        }
    }

    $html->pre_close();
    $html->_goto($current);

    return;
}


#
# A default handler in the event that 'die' gets called
#
sub die {
    #
    # First of all check if this occured within an "eval" block and
    # don't actually die if that is the case
    #
    my $i = 1;
    my @caller;
    while (@caller = caller($i)) {
        if ($caller[3] =~ /^\(?eval\)?$/) {
            return;
        }
        $i++;
    }
    my $self = __PACKAGE__->instance();
    if ($self->{cgi_sent}) {
        die "'die' was called after browser output sent, with: @_";
        if ($self->{debug}) {
            $self->{'log'}->l("'die' was called after browser output sent, with: @_");
        }
    }

    if ($self->{debug}) {
        (my @tmp = @_) =~ s/\n//mg;
        foreach (@_) {
            (my $x = $_) =~ s/\n$//g;
            $self->{'log'}->l('error:', $x);
        }
    }
    $self->{cgi_header}->status('500 Internal Server Error');
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
  my $cgi  = NCGI->new();
  my $html = $cgi->html;

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

  my $query = $cgi->query;
  if ($query->{submit}) {
    $html->p('I think your name is ', $query->{name});
  }


  if (param()) {
    print "Your name is",em(param('name')),p,
    "The keywords are: ",em(join(", ",param('words'))),p,
    "Your favorite color is ",em(param('color')),
    hr;
  }

  $cgi->respond();

=head1 DESCRIPTION

B<NCGI> has the same basic function as the well known L<CGI> module.
It is an aide for authors writing CGI scripts. The advantages over CGI
are

 * Smaller and simpler Codebase: 300 lines vs 7000 lines
 * Modular/maintainable Codebase: separate Header, XHTML, Query Classes
 * Better output: Based on XML::API for consistent XHTML
 * Better debugging: in-built logging with timing functions
 * Different API

The disadvantages over CGI are

 * Different API
 * Less features
 * Probably not as portable

See http://rekudos.net/parselog/ to see it in action.

=head1 METHODS

=head2 new(%hash)

Create a "Log::Parse" object. The %hash looks approximately like this:

   my %args  = (
        file        => '',
        filetype    => '',
        handlers    => '',
        libdir      => '',
        step        => '',
        rrdrra      => '',
        apache_domain => '',
        debug       => 0,
        @_
    );

but will vary depending on the type of handlers.

=head2 parse()

Parses a logfile and creates RRDs according to the configuration given
for the new() method.

=head1 SEE ALSO

L<NCGI::Header>, L<NCGI::Query>, L<XML::API>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut

