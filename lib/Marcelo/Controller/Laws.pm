package Marcelo::Controller::Laws;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller'; }

sub base :Chained('/base') PathPart('leis-populares') CaptureArgs(0) {
    my ( $self, $c ) = @_;

    push @{$c->stash->{breadcrumbs}},
      { title => 'Leis Populares', uri => $c->uri_for_action('/laws/index') };

    $c->stash(post_section => 'law',
              post_section_title => 'Leis Populares',
              post_controller => 'laws');
}

sub object :Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $post_id ) = @_;
    $c->forward('/forum/object', [$post_id]);
}

sub index :Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('/forum/index');
    $c->stash(template => 'forum/index.tt');
}

sub details :Chained('object') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('/forum/details');
    $c->stash(template => 'forum/details.tt');
}

sub add :Chained('base') PathPart('adicionar') Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('/forum/add');
    $c->stash(template => 'forum/add.tt');
}

sub edit :Chained('object') PathPart('editar') Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('/forum/edit');
    $c->stash(template => 'forum/edit.tt');
}

sub comment :Chained('object') PathPart('comentar') Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('/forum/comment');
    $c->stash(template => 'forum/comment.tt');
}

sub delete :Chained('object') PathPart('deletar') Args(0) {
    my ( $self, $c ) = @_;
    $c->forward('/forum/delete');
    $c->stash(template => 'forum/delete.tt');
}

__PACKAGE__->meta->make_immutable;

1;
