# Tests for NCGI package

use strict;
use warnings;
use Test::More;

BEGIN { plan tests => 6 };

use NCGI;
ok(1); # all use statements worked
my $q = NCGI->query;
ok(1);
my $response = NCGI->r;
ok(1);
my $header = $response->header;
ok(1);
my $x = $response->xhtml;
ok(1);
NCGI->respond;
ok(1);
ok(! NCGI->respond);

