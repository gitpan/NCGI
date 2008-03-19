package NCGI::Query;
use strict;
use warnings;
use base 'NCGI::Singleton';
use Encode;
use I18N::LangTags qw(implicate_supers);
use I18N::LangTags::Detect;
use NCGI::Cookie;
use CGI::Util qw(unescape);


our $VERSION = '0.07';

# Class::Singleton::instance() call
sub _new_instance {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {
        @_,
    };

    $self->{q_params} = {};
    $self->{q_full}   = '';
    $self->{q_type}   = 'NOQUERY';


    if ($ENV{CONTENT_LENGTH}) {
        $self->{q_type}  = 'POST';
        my $length = read(STDIN, $self->{q_full}, $ENV{CONTENT_LENGTH});
        if (!defined($length) or $length != $ENV{CONTENT_LENGTH}) {
            warn "Could not read from STDIN: $!";
            return undef;
        }
    }
    elsif ($ENV{QUERY_STRING}) {
        $self->{q_type} = 'GET';
        $self->{q_full} = $ENV{QUERY_STRING};
    }
    chomp($self->{q_full});

    $self->{q_params} = {};
    foreach (split(/[&;]/, $self->{q_full})) {
        my ($key, $val) = split('=', $_, 2);
        if (!eval { $key = Encode::decode_utf8(unescape($key));
                    $val = Encode::decode_utf8(unescape($val));1;}) {
            warn $@;
        }
        $val =~ s/\r//g;
        if (exists($self->{q_params}->{$key})) {
            my $ref = ref($self->{q_params}->{$key});
            if ($ref eq 'ARRAY') {
                push(@{$self->{q_params}->{$key}}, $val)
            }
            else {
                $self->{q_params}->{$key} = [$self->{q_params}->{$key}, $val],
            }
        }
        else {
            $self->{q_params}->{$key} = $val,
        }
    }

    $self->{q_cookies} = NCGI::Cookie::fetch();

    my @langs = implicate_supers(I18N::LangTags::Detect::detect);
    my @locales;
    foreach my $lang (@langs) {
#        if ((my $loc = $lang) =~ s/-(.*)/'_'.uc($1)/e) {
        (my $loc = $lang) =~ s/-(.*)/'_'.uc($1)/e;
            push(@locales, $loc);
#        };
    }

    $self->{q_langs}   = \@langs;
    $self->{q_locales} = \@locales;

    bless ($self, $class);
    return $self;
}

# ----------------------------------------------------------------------
# Public methods
# ----------------------------------------------------------------------

#
# Boolean to check if a GET or POST query was made
#
sub isquery {
    my $self = shift;
    return ($self->{q_type} ne 'NOQUERY');
}

#
# Boolean to check if a GET query was made
#
sub isget {
    my $self = shift;
    return ($self->{q_type} eq 'GET');
}

#
# Boolean to check if a POST query was made
#
sub ispost {
    my $self = shift;
    return ($self->{q_type} eq 'POST');
}

#
# Return the value of a query parameter
#
sub param {
    my $self = shift;
    my $param = shift;
    return unless exists($self->{q_params}->{$param});
    my $val = $self->{q_params}->{$param};
    wantarray && (ref($val) eq 'ARRAY') && return @{$val};
    (ref($val) eq 'ARRAY') && return $val->[0];
    wantarray && return ($val);
    return $val;
}

#
# Return HASHREF of all query items
#
sub params {
    my $self = shift;
    return $self->{q_params};
}

#
# Return the string that makes up the query
#
sub full_query {
    my $self = shift;
    return $self->{q_full};
}

#
# Return the value of a cookie sent
#
sub cookie {
    my $self = shift;
    my $param = shift;
    exists($self->{q_cookies}->{$param}) && return $self->{q_cookies}->{$param};
    return undef;
}

#
# Return HASHREF of all cookies
#
sub cookies {
    my $self = shift;
    return $self->{q_cookies};
}

#
# Return list of requested languages
#
sub languages {
    my $self = shift;
    return @{$self->{q_langs}} if (wantarray);
    return $self->{q_langs};
}

#
# Return list of requested locales
#
sub locales {
    my $self = shift;
    return @{$self->{q_locales}};
}

#
# Return a string of all query parameters in the form 'key = value'
#
sub dump_params {
    my $self = shift;
    my $str = '';
    while (my ($key, $val) = each %{$self->{q_params}}) {
        $val = '******' if ($key =~ /pass/);
        $str .= "$key = $val\n";
    }
    return $str;
}

#
# Return a string of all cookies in the form 'name = value'
#
sub dump_cookies {
    my $self = shift;
    my $str;
    while (my ($key, $val) = each %{$self->{q_cookies}}) {
        $str .= "$key = $val\n";
    }
    return $str;
}


1;

__END__

=head1 NAME

NCGI::Query - HTTP GET/POST Query/Request object for NCGI

=head1 SYNOPSIS

  use NCGI::Query;
  my $q = NCGI::Query->instance();

  print "Content-Type: text/plain\n\n";
  if ($q->isquery) {
    print "GET\n" if $q->isget();
    print "POST\n" if $q->isget();
    print "Your submit button is called: ", $q->param('submit');
    print "Your submitted name as: ", $q->params->{'name'};
  }
  else {
    print "No query\n";
  }

=head1 DESCRIPTION

B<NCGI::Query> provides an interface to GET and POST queries sent by
user agents.

=head1 METHODS

=head2 instance()

Return a reference to the current request. NCGI::Query is a Singleton
class. See Class::Singleton on CPAN for details on what this means.

=head2 isquery()

Boolean indicating whether a GET or POST query was received.

=head2 isget()

Boolean indicating whether a GET query was received.

=head2 ispost()

Boolean indicating whether a POST query was received.

=head2 param()

Takes a single argument (the key) and returns the query value. Will
return a list if called in array context. Useful for multiple parameters
of the same name (eg. html multi option lists).

=head2 params()

Returns a reference to a HASH containing all query items.

=head2 full_query()

Returns the raw query string

=head2 cookie()

Takes a single argument (the cookie) and returns the cookie value.

=head2 cookies()

Returns a reference to a HASH containing all cookies

=head2 languages()

Returns an ordered list of preferred languages for this request. Basically
a shortcut to I18N::LangTags::implicate_supers(I18N::LangTags::Detect::detect);

=head2 locales()

Returns an ordered list of preferred languages for this request, formatted
for use by POSIX::setlocale. Browsers seem to give 'en-us' and the locale
system has definitions called 'en_US'...

=head2 dump_params()

Returns a string representation of all query items and their values.

=head2 dump_cookies()

Returns a string representation of all cookies and their values.

=head1 SEE ALSO

L<NCGI::Singleton>, L<NCGI::Cookie>, L<NCGI>

=head1 AUTHOR

Mark Lawrence E<lt>nomad@null.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2007 Mark Lawrence E<lt>nomad@null.netE<gt>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

=cut
