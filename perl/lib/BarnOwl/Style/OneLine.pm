use strict;
use warnings;

package BarnOwl::Style::OneLine;
# Inherit format_message to dispatch
use base qw(BarnOwl::Style::Default);

use constant BASE_FORMAT => '%s %-13.13s %-11.11s %-12.12s ';

sub description {"Formats for one-line-per-message"}

BarnOwl::create_style("oneline", "BarnOwl::Style::OneLine");

################################################################################

sub maybe {
    my $thing = shift;
    return defined($thing) ? $thing : "";
}

sub format_login {
  my $self = shift;
  my $m = shift;
  return sprintf(
    BASE_FORMAT,
    '<',
    $m->type,
    uc( $self->login(m) ),
    $self->pretty_sender($m))
    . ($self->login_extra($m) ? "at ".$self->login_extra($m) : '');
}

sub format_ping {
  my $self = shift;
  my $m = shift;
  return sprintf(
    BASE_FORMAT,
    '<',
    $m->type,
    'PING',
    $self->pretty_sender($m))
}

sub format_chat
{
  my $self = shift;
  my $m = shift;
  my $dir = lc($m->{direction});
  my $dirsym = '-';
  if ($dir eq 'in') {
    $dirsym = '<';
  }
  elsif ($dir eq 'out') {
    $dirsym = '>';
  }

  my $line;
  if ($m->is_personal) {

    # Figure out what to show in the subcontext column
    $line= sprintf(BASE_FORMAT,
                   $dirsym,
                   $m->type,
                   maybe($self->short_personal_context($m)),
                   ($dir eq 'out'
                    ? $self->pretty_recipient($m)
                    : $self->pretty_sender($m)));
  }
  else {
    $line = sprintf(BASE_FORMAT,
                    $dirsym,
                    maybe($self->context($m)),
                    maybe($self->subcontext($m)),
                    ($dir eq 'out'
                     ? $self->pretty_recipient($m)
                     : $self->pretty_sender($m)));
  }

  my $body = $self->body($m);
  $body =~ tr/\n/ /;
  $line .= $body;
  return $line;
}

# Format owl admin messages
sub format_admin
{
  my $self = shift;
  my $m = shift;
  my $line = sprintf(BASE_FORMAT, '<', 'ADMIN', '', '');
  my $body = $self->body($m);
  $body =~ tr/\n/ /;
  return $line.$body;
}


1;
