package NCGI;
use 5.006;
use strict;
use warnings;
use base 'NCGI::Singleton';
use Carp;
use Time::HiRes qw(time);
use NCGI::Query;
use NCGI::Response;

our $VERSION = '0.08';
our $on_warn = \&_warn_handler;
our $on_die  = \&_die_handler;


# NCGI::Singleton instantiator
sub _new_instance {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    # We would infinite loop if we handled warnings before singleton exists
    $main::SIG{__WARN__} = \&CORE::warn;
    $main::SIG{__DIE__} = \&CORE::die;

    my $self = {
        ctime    => time,
        response => NCGI::Response->new,
        query    => NCGI::Query->instance,
        sent     => 0,
        warnings => [],
        debugs   => [],
    };
    bless($self, $class);

    if ($main::DEBUG) {
        warn "debug: NCGI v$VERSION Init.\n";
    }

    # now we are allowed to handle warnings
    if ($ENV{SERVER_SOFTWARE}) {
        on_warn($on_warn);
        on_die($on_die);
    }
    return $self;
}


sub query {
    return NCGI->instance->{query};
}
sub q {
    return NCGI->instance->{query};
}


sub response {
    NCGI->instance->{response};
}
sub r {
    response;
}


sub frespond {
    return NCGI->respond('fast_string');
}


sub respond {
    my $self = NCGI->instance;
    shift;
    my $action = shift || 'as_string';

    if ($self->{sent}) {
        croak 'Attempt to respond() more than once';
        return;
    }

    # Why the perl -CSD flag doesn't work I don't know...
    binmode STDOUT, ":utf8"
        if ($self->{response}->content->_encoding eq 'UTF-8');

    if ($action eq 'as_string') {
        my $res = sprintf('%.3f', time - $self->{ctime});
        $self->{response}->content->{current} = undef;#_goto('html');
        $self->{response}->content->_comment(
            "NCGI v$NCGI::VERSION (response time: ${res}s)"
        );
        warn 'debug: NCGI sending reponse' if($main::DEBUG);
    }

    #
    # From here on it doesn't make sense for us to handle
    # warn and die
    #

    $self->_render_warnings();
    $main::SIG{__WARN__} = \&CORE::warn;
    $main::SIG{__DIE__} = \&CORE::die;

    print $self->{response}->$action;
    $self->{sent} = 1;
}


#
# Add all collected warnings to the content document, assuming it is
# derived from XML::API::XHTML
#
sub _render_warnings {
    my $self = shift;

    if (!@{$self->{warnings}}) {
        return;
    }

    my $x = $self->{response}->content;

    if (ref($x) and $x->isa('XML::API::XHTML')) {
        $x->_goto('body');
        $x->pre_open(-style => "text-align: left; clear: both;");

        my $prev = $self->{ctime};

        foreach my $w (@{$self->{warnings}}) {
            my $msg = $w->[1];
            if ($msg =~ s/^debug:\s*//) {
                $msg =~ s/(.*)\s+at .*?\/lib\/(.*?) line (\d+).*/$1 \($2:$3\)/;
                $x->_raw('<span style="color: #008880;">');
                $x->_add(sprintf("%.5f (+%.5f)",
                                $w->[0] - $self->{ctime},
                                $w->[0] - $prev));#,
                $x->_raw('</span>');
                $x->_add(' ' . $msg ."\n");
                $prev = $w->[0];
            }
            else {
                # use raw because we are inside a <pre>
                chomp($msg);
                $x->_raw('<span style="color: #ff0000;">'.
                         XML::API::_escapeXML($msg) ."</span>\n");
            }
        }
    }
    return;
}


#
# A handler to deal with 'warn' calls
#
sub _warn_handler {
    my $self = __PACKAGE__->instance();
    my $val  = shift;
    $val     = '*undef*' unless (defined($val));
    chomp($val);

    #
    # First of all check if this occured within an "eval" block and
    # don't actually die if that is the case. FIXME This doesn't apply to
    # warnings?
    #
    unless (defined($val) and $val =~ m/^debug:/i) {
        my $i = 1;
        while (my @caller = caller($i)) {
            if ($caller[3] =~ /^\(?eval\)?$/) {
                return;
            }
            $i++;
        }
    }

    if ($self->{sent}) {
        warn $val;
        return;
    }

    my ($package,$filename,$line) = caller;
    push(@{$self->{warnings}}, [time, $val, $package, $line]);
    return;
}


#
# A handler to override 'die' signals
#
sub _die_handler {
    my $self = __PACKAGE__->instance();
    my $val  = shift;
    $val     = '*undef*' unless (defined($val));
    chomp($val);


    #
    # First of all check if this occured within an "eval" block and
    # don't actually die if that is the case
    #
    my $i = 1;
    while (my @caller = caller($i)) {
        if ($caller[3] =~ /^\(?eval\)?$/) {
            return;
        }
        $i++;
    }

    if ($self->{sent}) {
        die "'die' was called after browser output sent, with: @_";
    }

#    warn 'debug: die: '. join('',@_) if($main::DEBUG);
#    my ($package,$filename,$line) = caller(0);
#    if ($package eq 'Carp') {
#        ($package,$filename,$line) = caller(1);
#    }
#    warn "First $package $line";
#    push(@{$self->{warnings}}, [time, $val, $package, $line]);

    my $x = $self->{response}->content;
    $x->_goto('body');
    $x->pre(-style => 'color: #ff0000;', $val);
    $x->pre('500 Internal Server Error');

    $self->{response}->header->status('500 Internal Server Error');
    $self->respond();
    die @_;
}


#
# In case the user wants to override what happens with warnings
#
sub on_warn {
    my $sub = shift;
    if (ref($sub) ne 'CODE') {
        croak 'usage: on_warn(CODEREF)';
    }
    $main::SIG{__WARN__} = $sub;
    $on_warn = $sub;
}


sub on_die {
    my $sub = shift;
    if (ref($sub) ne 'CODE') {
        croak 'usage: on_die(CODEREF)';
    }
    $main::SIG{__DIE__} = $sub;
    $on_die = $sub;
}


1;
__END__

=head1 NAME

NCGI - A Common Gateway Interface (CGI) Class

=head1 SYNOPSIS

  use NCGI;
  my $q = NCGI->query;
  my $x = NCGI->response->xhtml;

  $x->_set_lang('en');
  $x->_goto('head');
  $x->title('A Simple Example');

  $x->_goto('body');
  $x->h1('A Simple Form');

  $x->form_open();
  $x->_add("What's your name? ");
  $x->input(-type => 'text', -name => 'name');
  $x->input(-type => 'submit', -name => 'submit', -value => 'Submit');
  $x->form_close();

  $x->hr();

  if ($q->param('submit')) {
    $x->p('I think your name is ', $q->param('name'));
  }

  NCGI->respond;

=head1 DESCRIPTION

B<NCGI> is an aide for authors writing CGI scripts. It has the same
basic function as the well known L<CGI> module although with a
completely different interface.

=head1 WHEN TO USE NCGI?

B<NCGI> does not make sense if you are already using and are 
comfortable with the standard L<CGI> module. However if would
like to easily produce standards-compliant XHTML using a proper
object-oriented interface then this module might be interesting
for you.

The advantages of NCGI are:

* Has a true object oriented interface. The incoming query, the outgoing
header and the outgoing content are all objects. The content object
is modified via method calls mainting a true document object model.
This gives you the flexibility of creating content 'out of order'.
Ie you can create a 'title' element inside the 'head' element and
then add to the 'body' element, but go back later and add a 'link'
to the 'head'.

* Will always produce valid (and nicely indented) XML as long as you
use the API.

* Improved debugging - Warnings and 'die' statements are
automatically added to the content object allieviating the head
scratching that goes on when you receive an Internal Server Error. The
content that you created up to this point is still displayed and
the entire document is still conformant.

* Is based on a Singleton class (see L<Class::Singleton> for a description)
meaning that you can easily work with the same query/header/content
objects from multiple modules without having to pass around strings
or manage global objects.

The disadvantages of NCGI are

* Completely different API from CGI

* Probably not as portable

* Less features

=head1 METHODS

NCGI is a Singleton class. See L<Class::Singleton> on CPAN if you are
unfamiliar with Singltons. What this means is that you don't have to
create an object before you use these methods, you can call them
just like 'NCGI->query', and you can do this from any module and always
get the same object back.

=head2 query

Returns the L<NCGI::Query> object representing the inbound request from
the browser.

=head2 q

A shortcut for query().

=head2 response

Returns the L<NCGI::Response> object representing the reply. You can
modify this object to generate output.

=head2 r

A shortcut for response().

=head2 on_warn

By default the Perl 'warn' function is overridden so that warnings
are included xhtml response. If you want to turn this off you should
set on_warn to '\&CORE::warn'.

=head2 on_die

By default the Perl 'die' function is overridden to include the die
arguments in the html response. If you want to turn this off you should
set on_die to '\&CORE::die'.

=head2 respond

Sends the header and the content back to the user agent. Will complain
if called more than once.

=head2 frespond

Sends the header and a minimum length content back to the user agent
using the _fast_string method from L<XML::API>. Will complain if called
more than once.

=head1 SEE ALSO

L<CGI::Simple>, L<NCGI::Singleton>, L<NCGI::Response::Header>,
L<NCGI::Query>, L<NCGI::Response>

=head1 COMPATABILITY

v0.05 to v0.06 was a major cleanup and a better separation of
responsibility/function between the various modules. Some methods
were removed from NCGI, some added to other modules. Since I don't
know anyone actually using NCGI I'm willing to take the risk...

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

Feel free to send me a mail telling me if you have used this module.
Until now I'm the only known user...

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 Mark Lawrence <nomad@null.net>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut

