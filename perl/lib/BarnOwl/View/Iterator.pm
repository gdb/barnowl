use strict;
use warnings;

package BarnOwl::View::Iterator;

sub view {return shift->{view}}
sub index {return shift->{index}}

sub new {
    my $class = shift;
    my $self = {
        view     => undef,
        index    => undef,
       };
    return bless $self, $class;
}

sub range {
    my $self = shift;
    return $self->view->ranges->find_or_insert($self->index);
}

sub invalidate {
    my $self = shift;
    $self->{view} = undef;
    $self->{index} = undef;
}

sub valid {
    my $self = shift;
    return defined($self->view);
}

sub initialize_at_start {
    my $self = shift;
    my $view = shift;
    $self->{view}  = $view;
    $self->{index} = 0;
    BarnOwl::debug("Initialize at start");
}

sub initialize_at_end {
    my $self = shift;
    my $view = shift;
    my $range;

    BarnOwl::debug("Initialize at end");

    $self->{view}  = $view;
    $range = $self->view->ranges->find_or_insert(-1);
    $self->view->fill_back($range);
    $self->{index} = $range->next_fwd;
}

sub initialize_at_id {
    my $self = shift;
    my $view = shift;
    my $id   = shift;
    $self->{view} = $view;
    $self->{index} = $id;
    BarnOwl::debug("Initialize at $id");
}

sub clone {
    my $self = shift;
    my $other = shift;
    BarnOwl::debug("clone from @{[$other->{index}||0]}");
    $self->{view} = $other->{view};
    $self->{index} = $other->{index};
}

sub is_at_start {
    my $self = shift;
  {
      local $self->{index} = $self->index;
      return $self->prev;
  }
}

sub is_at_end {
    my $self = shift;
    $self->fixup;
    return !$self->view->message($self->index);
}

sub prev {
    my $self = shift;
    my $old_idx = $self->index;
    my $range = $self->range;
    
    do {
        if($self->index == $range->next_bk) {
            BarnOwl::debug("Back: fill, id=@{[$self->index]}");
            $self->view->fill_back($range);
            if($self->index == $range->next_bk) {
                # Reached start
                $self->{index} = $old_idx;
                return 1;
            }
        }
        $self->{index}--;
    } while(!$self->view->message($self->index));

    BarnOwl::debug("PREV newid=@{[$self->index]}");
    return 0;
}

sub fill_forward {
    my $self = shift;
    my $range = $self->range;
    
    if($self->index >= $range->next_fwd) {
        BarnOwl::debug("Forward: fill, id=@{[$self->index]}");
        $self->view->fill_forward($range);
        if($self->index >= $range->next_fwd) {
            # Reached end
            return 1;
        }
    }
    return 0;
}

sub fixup {
    my $self = shift;

    return 1 if $self->fill_forward;

    while(!$self->view->message($self->index)) {
        $self->{index}++;
        return 1 if $self->fill_forward;
    }
    return 0;
}

sub next {
    my $self = shift;

    return 1 if $self->fixup;
    $self->{index}++;
    return $self->fixup
}

sub get_message {
    my $self = shift;
    $self->fixup;
    BarnOwl::debug("get_message: index=@{[$self->index]}");
    return BarnOwl::message_list->get_by_id($self->index);
}

sub cmp {
    my $self = shift;
    my $other = shift;

    $self->fixup;
    $other->fixup;
    
    return $self->index - $other->index;
}

1;
