use utf8;
package Marcelo::Schema::Result::Post;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Core';
__PACKAGE__->load_components("InflateColumn::DateTime", "TimeStamp", "PassphraseColumn");
__PACKAGE__->table("posts");
__PACKAGE__->add_columns(
  "id",
  {
    data_type         => "integer",
    is_auto_increment => 1,
    is_nullable       => 0,
    sequence          => "posts_id_seq",
  },
  "root_post_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
  "post_id",
  { data_type => "integer", is_foreign_key => 1, is_nullable => 1 },
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
  "section",
  {
    data_type   => "text",
    is_nullable => 1,
    original    => { data_type => "varchar" },
  },
  "created",
  { data_type => "timestamp with time zone", is_nullable => 1 },
  "updated",
  { data_type => "timestamp with time zone", is_nullable => 1 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->belongs_to(
  "post",
  "Marcelo::Schema::Result::Post",
  { id => "post_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
);
__PACKAGE__->has_many(
  "posts",
  "Marcelo::Schema::Result::Post",
  { "foreign.post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->has_many(
  "posts_root_posts",
  "Marcelo::Schema::Result::Post",
  { "foreign.root_post_id" => "self.id" },
  { cascade_copy => 0, cascade_delete => 0 },
);
__PACKAGE__->belongs_to(
  "root_post",
  "Marcelo::Schema::Result::Post",
  { id => "root_post_id" },
  {
    is_deferrable => 0,
    join_type     => "LEFT",
    on_delete     => "CASCADE",
    on_update     => "CASCADE",
  },
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


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2018-04-14 13:44:35
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:srcltzow5F1WZ1MnGNhPeA

__PACKAGE__->add_columns('+created' => { set_on_create => 1 },
                         '+updated' => { set_on_create => 1,
                                         set_on_update => 1 });

sub thread_posts {
    my $self = shift;
    my $rs = $self->result_source->resultset;
    return $rs->search({ root_post_id => $self->root_post_id },
                       { prefetch => 'user',
                         order_by => [{ -desc => 'me.post_id' },
                                      { -asc => 'me.created' }] });
}

sub thread_updated {
    my $self = shift;
    use DateTime::Format::Flexible;
    return DateTime::Format::Flexible->parse_datetime
      ( substr($self->get_column('thread_updated'), 0, -3) );
}

sub people {
    my $self = shift;
    my @posts = $self->result_source->resultset->search
      ({ root_post_id => $self->root_post_id },
       { prefetch => 'user', order_by => { -asc => 'user.name' } });

    my %seen;
    my @result;
    for my $post (@posts) {
        if ( ! $seen{$post->user_id} ) {
            $seen{$post->user_id} = 1;
            push @result, $post->user->name;
        }
    }

    return @result;
}

__PACKAGE__->meta->make_immutable;

1;
