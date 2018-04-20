package Marcelo::Controller::Root;
use Moose;
use namespace::autoclean;
use utf8;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub base :Chained('/') PathPart('') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    push @{$c->stash->{breadcrumbs}},
      { title => 'Início', uri => $c->uri_for_action('/index') };
}

sub index :Path Args(0) {
    my ( $self, $c ) = @_;
}

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

sub end : ActionClass('RenderView') {}

sub login :Local Args(0) {
    my ( $self, $c ) = @_;

    if ($c->req->method eq 'POST') {
        my $usr = $c->req->params->{username};
        my $pwd = $c->req->params->{password};
        my $auth = $c->authenticate({ id => $usr, password => $pwd });
        if ($auth) { $c->res->redirect($c->uri_for_action('/index')) }
        else { $c->flash->{error_msg} = 'Erro no login.' }
    }
}

sub logout :Local Args(0) {
    my ( $self, $c ) = @_;
    $c->logout;
    $c->res->redirect($c->uri_for_action('/index'));
}

__PACKAGE__->meta->make_immutable;

1;
