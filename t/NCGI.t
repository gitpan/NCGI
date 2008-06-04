# Tests for NCGI package
use strict;
use warnings;
use Test::More;

my $capture;

BEGIN {
#    eval {require IO::Capture::Stdout;};
#    if ($@) {
        plan tests => 6; 
#    }
#    else {
#        plan tests => 8; 
#        $capture = IO::Capture::Stdout->new();
#    }

    use_ok('NCGI');
};
ok(1); # all use statements worked
my $q = NCGI->query;
ok(1);
my $response = NCGI->r;
ok(1);
my $header = $response->header;
ok(1);
my $x = $response->xhtml;
ok(1);

if (0 and $capture) {
    $capture->start;
    NCGI->respond;
    $capture->stop;

    ok(1);
    eval {
        $SIG{__WARN__} = \&Core::die;
        NCGI->respond;
    };
    like($@, qr/Attempt/, 'responding twice');
}

NCGI->response->rss->channel('this is my channel');
NCGI->respond;
