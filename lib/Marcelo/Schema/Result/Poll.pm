use utf8;
package Marcelo::Schema::Result::Poll;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");
__PACKAGE__->table("polls");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "polls_id_seq",
  },
  "user_id",
  {
    data_type      => "text",
    is_foreign_key => 1,
    is_nullable    => 1,
    original       => { data_type => "varchar" },
  },
  "title",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "body",
  { data_type => "text", is_nullable => 1 },
  "created",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->has_many(
  "poll_options",
  "Marcelo::Schema::Result::PollOption",
  { "foreign.poll_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "user",
  "Marcelo::Schema::Result::User",
  { id => "user_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2018-04-20 13:11:17
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:nFYQ3HKJFigHwqEbWOKqVA

sub votes {
    my ($self, $cond) = @_;
    my @options = $self->poll_options;
    return map { $_->poll_votes($cond) } @options;
}

sub stats {
    my $self = shift;
    my @res;
    my @poll_votes;
    for my $option ($self->poll_options(undef, { order_by => 'id' })) {
        my @n = $option->poll_votes;
        push @res, { option => $option, votes => scalar @n };
        push @poll_votes, @n;
    }

    my $total_votes = @poll_votes;

    for my $res (@res) {
        $res->{percentage} = 0;
        if ($total_votes > 0) {
            $res->{percentage} =
              sprintf '%.2f', $res->{votes} / $total_votes * 100;
            $res->{percentage} .= '%';
        }
    }

    return @res;
}

sub total_votes {
    my $self = shift;
    my @ids = map { $_->id } $self->poll_options;
    my @votes = $self->result_source->schema->resultset('PollVote')->search
      ({ poll_option_id => { -in => \@ids } });
    return scalar @votes;
}

__PACKAGE__->meta->make_immutable;
1;
