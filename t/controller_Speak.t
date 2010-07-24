use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'hackday2010' }
BEGIN { use_ok 'hackday2010::Controller::Speak' }

ok( request('/speak')->is_success, 'Request should succeed' );
done_testing();
