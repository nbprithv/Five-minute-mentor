#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Catalyst::Test', 'hackday2010' }

ok( request('/')->is_success, 'Request should succeed' );

done_testing();
