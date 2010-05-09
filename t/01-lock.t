use strict;

use Test::More tests => 15;
use Test::Exception;

use IO::File;
use TokyoTyrant;
use TokyoTyrantx::Lock::Client;
use TokyoTyrantx::Instance;

my $ti;

BEGIN {
    $ti = TokyoTyrantx::Instance->new( lockhash => {
            dir => '/tmp',
            host => '127.0.0.1',
            port => 4000,
            filename => "'*'",
        }
    );
    $ti->start;

    sleep(2);
}

# connect
my $client = TokyoTyrantx::Lock::Client->instance( hash => $ti->get_rdb ); 

# test
my $key = 123;

$TokyoTyrantx::Lock::Client::DEBUG = 1;

sub base_test {
    
    my $lock = $client->lock_or_die($key);
    ok( $lock, 'resource locked');
    isa_ok($lock, 'TokyoTyrantx::Lock');

    throws_ok { $client->lock( $key, or_die => 1, or_wait => 1 ) } qr/taken/, 'resource taken';

}

base_test();
    
my $lock = $client->lock_or_die($key);
ok( $lock, 'resource locked, resource was freed');
isa_ok($lock, 'TokyoTyrantx::Lock');

cmp_ok( $client->lock_count, '==', 1, '1 lock');
ok($client->release($key), 'explicit release');
cmp_ok( $client->lock_count, '==', 0, '0 lock');
ok($client->release($key), 'explicit release');
lives_ok( sub { undef( $lock ) }, 'another release (implicit) should not die');

$lock = $client->lock_or_die($key);
ok( $lock, 'lock again');
isa_ok($lock, 'TokyoTyrantx::Lock');

cmp_ok( $client->lock_count, '==', 1, '1 lock');
lives_ok( sub { undef( $lock) }, 'implicit release');
cmp_ok( $client->lock_count, '==', 0, '0 lock');

END {
    $ti->stop;
}
