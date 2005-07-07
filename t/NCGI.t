# Tests for NCGI package

use strict;
use warnings;
use Test::More;

BEGIN { plan tests => 7 };

use NCGI::Query;
use NCGI::Header;
use NCGI;
ok(1); # all use statements worked
my $header = NCGI::Header->instance;
ok(1);
my $query = NCGI::Query->instance;
ok(1);
my $cgi = NCGI->instance;
ok(1);
my $content = $cgi->content;
ok(1);
$cgi->respond;
ok(1);
ok(! $cgi->respond);

