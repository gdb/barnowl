use strict;
use warnings;

package BarnOwl::MessageList;

sub binsearch {
    my $list = shift;
    my $val  = shift;
    my $key  = shift || sub {return $_[0]};
    my $left = 0;
    my $right = scalar @{$list} - 1;
    my $mid = $left;
    while($left <= $right) {
        $mid = ($left + $right)/2;
        if($key->($list->[$mid]) < $val) {
            $left = $mid + 1;
        } else {
            $right = $mid - 1;
        }
    }
    return $mid;
}

my $__next_id = 0;

sub next_id {
    return $__next_id++;
}

sub new {
    my $class = shift;
    my $self = {messages => {}};
    return bless $self, $class;
}

sub set_attribute {
    
}

sub get_size {
    my $self = shift;
    return scalar keys %{$self->{messages}};
}

sub iterate_begin {
    my $self = shift;
    my $id   = shift;
    my $rev  = shift;
    $self->{keys} = [sort {$a <=> $b} keys %{$self->{messages}}];
    if($id < 0) {
        $self->{iterator} = scalar @{$self->{keys}} - 1;
    } else {
        $self->{iterator} = binsearch($self->{keys}, $id);
    }
    
    $self->{iterate_direction} = $rev ? -1 : 1;
}

sub iterate_next {
    my $self = shift;
    if($self->{iterator} >= scalar @{$self->{keys}}) {
        return undef;
    }
    return $self->get_by_id($self->{keys}->[$self->{iterator}++]);
}

sub iterate_done {
    # nop
}

sub get_by_id {
    my $self = shift;
    my $id = shift;
    return $self->{messages}{$id};
}

sub add_message {
    my $self = shift;
    my $m = shift;
    $self->{messages}->{$m->id} = $m;
}

sub expunge {
    my $self = shift;
    for my $message (values %{$self->{messages}}) {
        if($message->is_deleted) {
            delete $self->{messages}->{$message->id};
        }
    }
}

1;