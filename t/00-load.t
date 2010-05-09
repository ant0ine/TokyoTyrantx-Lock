#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'TokyoTyrantx::Lock' );
	use_ok( 'TokyoTyrantx::Lock::Client' );
}

diag( "Testing TokyoTyrantx::Lock $TokyoTyrantx::Lock::VERSION, Perl $], $^X" );
