# Tests for NCGI package
use strict;
use warnings;
use Test::More;

BEGIN {
    plan tests => 11; 
};

use_ok('NCGI::Cookie');
can_ok('NCGI::Cookie', qw/
    new
    fetch
    new
    name
    value
    expires
    max_age
    path
    domain
    expire_cookie
    _as_string
    _cookie_scrub
    _cookie_date
/);

my $c = NCGI::Cookie->new(
    name => 'test',
    value => 'testvalue',
    expires => 1221927411,
);

is($c,'test=testvalue; Path=/; Expires=Sat 20-Sep-2008 16:16:51 GMT; Version=1', $c);

$c->value('newvalue');
is($c,'test=newvalue; Path=/; Expires=Sat 20-Sep-2008 16:16:51 GMT; Version=1', $c);

$c->domain('mydomain');
is($c,'test=newvalue; Path=/; Domain=mydomain; Expires=Sat 20-Sep-2008 16:16:51 GMT; Version=1', $c);

my $nc = NCGI::Cookie::fetch($c);
isa_ok($nc, 'HASH');
is($nc->{test},'newvalue', 'value check');

$c->domain(undef);
is($c,'test=newvalue; Path=/; Expires=Sat 20-Sep-2008 16:16:51 GMT; Version=1', $c);

$c->max_age(60);
is($c,'test=newvalue; Path=/; Max-Age=60; Expires=Sat 20-Sep-2008 16:16:51 GMT; Version=1', $c);

$c->name(undef);

eval {
    my $x = ''.$c;
};
like($@, qr/Cookie Name and Value must be defined/, 'name undefined');

$c->name('test');
$c->value(undef);
eval {
    my $x = ''.$c;
};
like($@, qr/Cookie Name and Value must be defined/, 'value undefined');

