package TokyoTyrantx::Lock::Client;
use strict;
use warnings;

use Time::HiRes qw( usleep );
use TokyoTyrantx::Lock;

our $DEBUG = 0;

=head1 NAME

TokyoTyrantx::Lock::Client

=head1 SYNOPSIS

 # start an In Memory Tokyo Tyrant before.
 # (TokyoTyrantx::Instance can help)
 
 my $ti = TokyoTyrantx::Instance->new( lockhash => {
         dir => '/tmp',
         host => '127.0.0.1',
         port => 4000,
         filename => "'*'",
     }
 );
 $ti->start;

 # then in your code when you need locking
 # (TokyoTyrantx::Instance can help again to get the $rdb)
 
 use TokyoTyrantx::Lock::Client;
 
 my $c = TokyoTyrantx::Lock::Client->instance( hash => $ti->get_rdb );

 my $l = $c->lock($resource_key);

 # play with the locked resource
 ...

 # release it
 undef $l;

=head1 METHODS

=cut

my $Instance;

use constant DEFAULT_N_TIMES => 5;
use constant DEFAULT_USLEEP => 100000;

sub _new_instance {
    my $class = shift;
    my %args = @_;
    die 'hash required' unless $args{hash};
    die 'hash is not a TokyoTyrant::RDB' 
        unless $args{hash}->isa('TokyoTyrant::RDB');
    return bless \%args, $class;
}

=head2 instance( hash => $rdb );

Pass the parameters the first time you call instance, then call it without parameter.

The only required parameter is hash that should specify the TokyoTyrant::RDB object.

Optional parameters:

=over 4

=item * default_n_times

define the default value of n_times, if not specified, defaults to 5


=item * default_usleep

define the default sleep dealy in microseconds, if not specified, defaults to 100000

=back

=cut

sub instance {
    my $class = shift;
    return $Instance ||= $class->_new_instance(@_);
}

=head2 lock( $key, %opts )

%opts can be used to specify the following options:

=over 4

=item * or_die

die if instead of returing undef if the resource cannot be locked 

=item * or_wait

enable the retry mechanism, retry n_times, with a sleep time equal to the number of the try time the usleep delay.

=item * n_times

=item * sleep

=back

=cut

sub lock {
    my $self = shift;
    my $key = shift;
    my %opts = @_;

    my $l = TokyoTyrantx::Lock->new($key);
    return $l if $l;

    if ($opts{or_wait}) {
        my $n_times = $opts{n_times} || $self->{defaut_n_times} || DEFAULT_N_TIMES(); 
        my $usleep = $opts{usleep} || $self->{defaut_usleep} || DEFAULT_N_TIMES(); 
        for my $try (1..$n_times) {
            print STDERR "cannot get the lock, retrying ($try)\n" if $DEBUG;
            usleep( $usleep * $try );
            $l = TokyoTyrantx::Lock->new($key);
            return $l if $l;
        }
    }

    if ($opts{or_die}) {
        die "resource already taken (key $key)" unless $l;
        return $l;
    }

    return $l;
}

=head2 lock_or_wait( $key )

Shortcut for lock( $key, or_wait => 1 )

=cut

sub lock_or_wait {
    my $self = shift;
    my ($key) = @_;
    return $self->lock( $key, or_wait => 1 );
}

=head2 lock_or_die( $key )

Shortcut for lock( $key,  or_die => 1 )

=cut

sub lock_or_die {
    my $self = shift;
    my ($key) = @_;
    return $self->lock( $key, or_die => 1 );
}

=head2 release( $key )

=cut

sub release {
    my $self = shift;
    my ($key) = @_;
    return TokyoTyrantx::Lock->release( $key );
}

=head2 get_tyrant_client

get the tokyo tyrantclient

=cut

sub get_tyrant_client {
    my $self = shift;
    return $self->{hash};
}

=head2 lock_count

Return the number of locks currently in the hash.
Of course, assumes that the hash is not used for something else.

=cut

sub lock_count {
    my $self = shift;
    my $rdb = $self->get_tyrant_client;
    return $rdb->rnum();
}

=head1 AUTHOR

Antoine Imbert, C<< <antoine.imbert at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Antoine Imbert, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
