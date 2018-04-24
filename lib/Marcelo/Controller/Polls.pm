package Marcelo::Controller::Polls;
use Moose;
use namespace::autoclean;
use utf8;
use HTML::FormFu;

BEGIN { extends 'Catalyst::Controller'; }

sub base :Chained('/base') PathPart('enquetes') CaptureArgs(0) {
    my ( $self, $c ) = @_;
    my $polls_rs = $c->model('DB::Poll');

    push @{$c->stash->{breadcrumbs}},
      { title => 'Enquetes', uri => $c->uri_for_action('/polls/index') };

    $c->stash(polls_rs => $polls_rs);
}

sub object :Chained('base') PathPart('') CaptureArgs(1) {
    my ( $self, $c, $poll_id ) = @_;
    my $poll = $c->stash->{polls_rs}->find($poll_id);

    if (!$poll) { $c->detach('/default') }

    $c->stash(poll => $poll);
}

sub index :Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
    my @polls = $c->stash->{polls_rs}->search(undef, { order_by => 'title' });

    $c->stash(polls => \@polls);
}

sub details :Chained('object') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
    my $poll = $c->stash->{poll};

    my $form = HTML::FormFu->new(_formfu_config_vote($poll->id));
    $form->stash->{schema} = $c->model('DB')->schema;
    $form->process($c->req->params);

    my $vote;
    if ($c->user_exists) {
        ($vote) = $poll->votes({ user_id => $c->user->id })
    }

    if ($form->submitted_and_valid) {
        if (!$c->user_exists) { $c->detach('/default') }

        $form->add_valid('user_id', $c->user->id);
        if ($vote) { $vote->delete }
        $form->model->create;

        $c->flash->{success_msg} = 'Voto efetuado.';
        $c->res->redirect($c->uri_for_action('/polls/details', [$poll->id]));
        $c->detach;
    }
    elsif ($vote) {
        $form->model->default_values($vote);
    }

    push @{$c->stash->{breadcrumbs}},
      { title => $poll->title,
        uri => $c->uri_for_action('/polls/details', [$poll->id]) };

    $c->stash(form => $form, stats => [$poll->stats]);
}

sub add :Chained('base') PathPart('adicionar') Args(0) {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('admin')) { $c->detach('/default') }

    my $form = HTML::FormFu->new( _formfu_config() );
    $form->stash->{schema} = $c->model('DB')->schema;
    $form->get_element({ type => 'Fieldset' })->get_element
      ({ type => 'Repeatable' })->repeat(3);
    $form->process($c->req->params);

    if ($form->submitted_and_valid) {
        my $poll = $form->model->create;

        $c->flash->{success_msg} = 'Registro adicionado';
        $c->res->redirect($c->uri_for_action('/polls/details', [$poll->id]));
        $c->detach;
    }

    $c->stash(form => $form);
}

sub edit :Chained('object') PathPart('editar') Args(0) {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('admin')) { $c->detach('/default') }

    my $poll = $c->stash->{poll};

    my $form = HTML::FormFu->new( _formfu_config() );
    $form->stash->{schema} = $c->model('DB')->schema;
    $form->process($c->req->params);

    if ($form->submitted_and_valid) {
        $form->model->update($poll);

        $c->flash->{success_msg} = 'Registro editado';
        $c->res->redirect($c->uri_for_action('/polls/details', [$poll->id]));
        $c->detach;
    }
    else {
        $form->model->default_values($poll);
    }

    $c->stash(form => $form);
}

# TODO
sub delete :Chained('object') PathPart('deletar') Args(0) {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('admin')) { $c->detach('/default') }
}

sub _formfu_config {
    return {
        languages => ['pt_br'],
        auto_container_class => 'form-group',
        default_args => {
            elements => {
                'Text|Textarea|Select|File' => {
                    attrs => { class => 'form-control' }, },
                'Radiogroup' => {
                    attrs => { class => 'form-check' } },
            },
        },
        model_config => {
            resultset => 'Poll',
            model_config => { empty_rows => 3 }
        },
        elements => [
            { type => 'Text',
              name => 'title',
              label => 'Título',
              constraints => 'Required' },
            { type => 'Textarea',
              name => 'body',
              label => 'Corpo',
              constraints => 'Required' },
            { type => 'Hidden',
              name => 'poll_options_counter' },
            { type => 'Fieldset',
              legend => 'Opções',
              element =>
                { type => 'Repeatable',
                  nested_name => 'poll_options',
                  counter_name => 'poll_options_counter',
                  model_config => { empty_rows => 3 },
                  attrs => { class => 'inner-form-group' },
                  elements => [
                      { type => 'Hidden',
                        name => 'id' },
                      { type => 'Text',
                        name => 'name',
                        label => 'Nome' },
                      { type => 'Checkbox',
                        name => 'delete_option',
                        label => 'Deletar opção?',
                        model_config => { delete_if_true => 1 } } ]
                },
            },
            { type => 'Submit',
              value => 'Enviar' }
        ],
    },
}

sub _formfu_config_vote {
    my $poll_id = shift;

    return {
        languages => ['pt_br'],
        model_config => { resultset => 'PollVote' },
        attrs => { id => 'vote-form' },
        elements => [
            { type => 'Radiogroup',
              name => 'poll_option_id',
              label => 'Opções',
              auto_id => '%n_%c',
              model_config => {
                  resultset => 'PollOption',
                  condition => { poll_id => $poll_id },
                  attrs => { order_by => 'id' } },
            },
            { type => 'Submit',
              value => 'Votar' }
        ],
    },
}

__PACKAGE__->meta->make_immutable;

1;
