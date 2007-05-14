# Load the Module::Install bundled in ./inc/
use inc::Module::Install;

name            'NCGI';
license         'GPL';
all_from        'lib/NCGI.pm';
requires        'XML::API'      => '0.14';
requires        'Time::HiRes'   => 0;
build_requires  'Test::More'    => '0.42';

auto_install;

WriteAll;