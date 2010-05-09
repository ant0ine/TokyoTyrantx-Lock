package TokyoTyrantx::Lock;
use warnings;
use strict;

use TokyoTyrantx::Lock::Client; 

=head1 NAME

TokyoTyrantx::Lock - A very simple lock mechanism based on Tokyo Tyrant

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 DESCRIPTION

TokyoTyrantx::Lock is a very simple lock mechanism based on Tokyo Tyrant. 
This is the lock class, normally, you don't have to create the lock object yourself, instead you should use the lock client: TokyoTyrantx::Lock::Client

=head1 METHODS

=head2 new( $key )

Create a new lock, see the lock client.

=cut

use constant RDB_TRY => 3;

sub new {
    my $class = shift;
    my ($key) = @_;
    die 'key required' unless $key;
    my $instance = eval { TokyoTyrantx::Lock::Client->instance };
    die 'Cannot get the TokyoTyrantx::Lock::Client instance' if $@;
    my $rdb = $instance->get_tyrant_client;
    for my $try (1..RDB_TRY()) {
        if ($rdb->putkeep( $key, time )) {
            last;
        }
        else {
            if ($rdb->ecode == $rdb->ERECV && $try < RDB_TRY()) {
                # network error
                next;
            }
            elsif ($rdb->ecode == $rdb->EKEEP) {
                # record exists
                return undef;
            }
            else {
                my $msg = $rdb->errmsg($rdb->ecode);
                die "error while trying to obtain the lock (key $key) ".$msg;
            }
        }
    }
    return bless { key => $key }, $class;
}

=head2 key

Return the lock key.

=cut

sub key { $_[0]->{key} }

=head2 release

Releases the lock.
Can be also used as a class method like this: TokyoTyrantx::Lock->release($key)

=cut

sub release {
    my $self = shift;
    my ($key) = @_;
    $key ||= $self->key;
    my $instance = eval { TokyoTyrantx::Lock::Client->instance };
    die 'Cannot get the TokyoTyrantx::Lock::Client instace' if $@;
    my $rdb = $instance->get_tyrant_client;
    for my $try (1..RDB_TRY()) {
        if ($rdb->out($key) ) {
            last;
        }
        else {
            if ($rdb->ecode == $rdb->ERECV && $try < RDB_TRY()) {
                # retrying
                next;
            }
            elsif ($rdb->ecode == $rdb->ENOREC) {
                # no record found
                last;
            }
            else {
                my $msg = $rdb->errmsg($rdb->ecode);
                die "error while trying to release the lock (key $key) ".$msg;
            }
        }
    }
    return 1;
}

=head2 DESTROY 

Release the lock. This means that when the $lock object is destroyed, by going out of the scope for example, then the lock is released.

=cut

sub DESTROY {
    my $self = shift;
    $self->release;
}

=head1 AUTHOR

Antoine Imbert, C<< <antoine.imbert at gmail.com> >>

=head1 COPYRIGHT & LICENSE

Copyright 2009 Antoine Imbert, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;

