use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'TokyoTyrantx::Lock',
    license             => 'perl',
    dist_author         => 'Antoine Imbert <antoine.imbert@gmail.com>',
    dist_version_from   => 'lib/TokyoTyrantx/Lock.pm',
    build_requires => {
        'Test::More' => 0,
        'TokyoTyrant' => 0,
        'TokyoTyrantx::Instance' => 0,
        'Time::HiRes' => 0,
    },
    add_to_cleanup      => [ 'TokyoTyrantx-Lock-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
