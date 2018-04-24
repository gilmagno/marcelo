package Marcelo::Controller::Forum;
use Moose;
use namespace::autoclean;
use utf8;
use HTML::FormFu;

BEGIN { extends 'Catalyst::Controller'; }

sub object :Private {
    my ($self, $c, $post_id) = @_;
    my $posts_rs = $c->model('DB::Post');
    my ($post) = $posts_rs->search({ 'me.id' => $post_id,
                                     section => $c->stash->{post_section} },
                                   { prefetch => 'user' });
    if (not $post) { $c->detach('/default') }

    push @{$c->stash->{breadcrumbs}},
      { title => $post->title,
        uri => $c->uri_for_action
          ('/' . $c->stash->{post_controller} . '/details', [$post->id]) };
    $c->stash(post => $post);
}

sub index :Private {
    my ( $self, $c ) = @_;
    my $pagination = $c->stash->{pagina} || 1;
    my $posts_rs = $c->model('DB::Post');

    my $sub_query1 = $posts_rs->search
      ({ root_post_id => { -ident => 'me.id' } },
       { columns => 'sub_query1.updated',
         order_by => { -desc => 'sub_query1.updated' },
         rows => 1,
         alias => 'sub_query1' });

    my $sub_query2 = $posts_rs->search
        ({ root_post_id => { -ident => 'me.id' } },
         { select => { count => 'sub_query2.id' },
           alias => 'sub_query2' });

    $posts_rs = $posts_rs->search
      ({ 'post_id' => undef, 'section' => $c->stash->{post_section} },
       { '+select' => [$sub_query1->as_query, $sub_query2->as_query],
         '+as' => ['thread_updated', 'thread_count'],
         order_by => { -desc => $sub_query1->as_query },
         prefetch => 'user',
         page => $pagination });

    $c->stash(posts => [$posts_rs->all], pager => $posts_rs->pager);
}

sub details :Private {
    my ( $self, $c ) = @_;
    my $post = $c->stash->{post};
    my @posts = $post->thread_posts;

    my $first_post = shift @posts; # the post that started the thread
    my @data_struct = construct(\@posts, $first_post);

    my $html_ul = @data_struct > 1 ?
      create_html_ul($c, $post, @data_struct) : '';

    $c->stash(html_ul => $html_ul);
}

sub construct {
    my ($posts, $post) = @_;
    my @children;
    my @fewer_posts;

    for my $item (@$posts) {
        if ($item->post_id == $post->id) { push @children, $item }
        else { push @fewer_posts, $item }
    }

    if (!@children) { return $post }
    else {
        $posts = \@fewer_posts;
        return $post, [ map { construct($posts, $_) } @children ]
    }
}

sub create_html_ul {
    my $c = shift;
    my $post = shift;
    my @data = @_;
    my $html = '<ul>';

    for my $item (@data) {
        if (ref($item) eq 'ARRAY') {
            $html .= create_html_ul($c, $post, @$item)
        }
        else {
            if ($item->id == $post->id) {
                $html .= '<li><b>' . 'Comentário' . '</b>' .
                  ' por ' . $item->user->name . ' em ' .
                  $item->created->strftime('%d/%m/%y %H:%M:%S') . '</li>'
            }
            else {
                my $uri = $c->uri_for_action
                  ('/' . $c->stash->{post_controller} . '/details', [$item->id]);
                $html .= qq{<li><a href="$uri">} . 'Comentário' . "</a>" .
                  ' por ' . $item->user->name . ' em ' .
                  $item->created->strftime('%d/%m/%y %H:%M:%S') . '</li>'
            }
        }
    }

    $html .= '</ul>';
    return $html;
}

sub add :Private {
    my ( $self, $c ) = @_;
    if (not $c->user_exists) { $c->detach('/default') }
    if ($c->stash->{post_section} eq 'law' && !$c->check_user_roles('admin')) {
        $c->detach('/default')
    }

    my $form = HTML::FormFu->new( _formfu_config() );
    $form->stash->{schema} = $c->model('DB')->schema;
    $form->process($c->req->params);

    if ($form->submitted_and_valid) {
        $form->add_valid('user_id', $c->user->id);
        $form->add_valid('section', $c->stash->{post_section});
        my $post = $form->model->create;
        $post->root_post_id($post->id);
        $post->update;

        $c->flash->{success_msg} = 'Registro adicionado.';

        $c->res->redirect($c->uri_for_action(
            "/" . $c->stash->{post_controller} . "/details", [$post->id]));
    }

    $c->stash(form => $form);
}

sub edit :Private {
    my ( $self, $c ) = @_;
    if (not $c->user_exists) { $c->detach('/default') }
    if ($c->user->id ne $c->stash->{post}->user_id
          && !$c->check_user_roles('admin')) { $c->detach('/default') }

    my $post = $c->stash->{post};

    my $form = HTML::FormFu->new( _formfu_config() );
    $form->stash->{schema} = $c->model('DB')->schema;
    if (!$c->check_user_roles('admin')) {
        $form->remove_element($form->get_element({ name => 'title' }));
    }
    $form->process($c->req->params);

    if ($form->submitted_and_valid) {
        $form->add_valid('user_id', $c->user->id);
        $form->model->update($post);

        $c->flash->{success_msg} = 'Registro editado.';

        $c->res->redirect($c->uri_for_action(
            "/" . $c->stash->{post_controller} . "/details", [$post->id]));
    }
    else {
        $form->model->default_values($post);
    }

    $c->stash(form => $form);
}

sub comment :Private {
    my ( $self, $c ) = @_;
    if (not $c->user_exists) { $c->detach('/default') }

    my $form = HTML::FormFu->new( _formfu_config() );
    $form->stash->{schema} = $c->model('DB')->schema;
    $form->remove_element( $form->get_element({ name => 'title' }) );
    $form->process($c->req->params);

    if ($form->submitted_and_valid) {
        $form->add_valid('user_id', $c->user->id);
        $form->add_valid('root_post_id', $c->stash->{post}->root_post_id);
        $form->add_valid('post_id', $c->stash->{post}->id);
        $form->add_valid('section', $c->stash->{post_section});

        my $title = $c->stash->{post}->title;
        if ($title !~ /^Re: /) { $title = "Re: $title" }
        $form->add_valid('title', $title);

        my $comment = $form->model->create;

        $c->flash->{success_msg} = 'Registro adicionado.';
        $c->res->redirect($c->uri_for_action(
            "/" . $c->stash->{post_controller} . "/details", [$comment->id]));
    }

    $c->stash(form => $form);
}

sub delete :Private {
    my ( $self, $c ) = @_;
    if (!$c->check_user_roles('admin')) { $c->detach('/default') }

    my $form = HTML::FormFu->new({
        languages => ['pt_br'],
        form_error_message => 'Erro. Verifique os campos do formulário.',
        auto_container_class => 'form-group',
        default_args => { elements => { 'Text|Textarea' => {
            attrs => { class => 'form-control' } } } },
        model_config => { resultset => 'Post' },
        attrs => { id => 'post-form' },
        elements => [
            { type => 'Text',
              name => 'confirmation',
              label => 'Confirmação',
              constraints => ['Required',
                              { type => 'Regex',
                                regex => qr/deletar/ } ], },
            { type => 'Submit',
              name => 'submit',
              value => 'Enviar', },
        ],
    });
    $form->process($c->req->params);

    if ($form->submitted_and_valid) {
        $c->stash->{post}->delete;

        $c->flash->{success_msg} = 'Registro deletado.';
        $c->res->redirect($c->uri_for_action(
            "/" . $c->stash->{post_controller} . "/index"));
    }

    $c->stash(form => $form);
}

sub _formfu_config {
    return {
        languages => ['pt_br'],
        form_error_message => 'Erro. Verifique os campos do formulário.',
        auto_container_class => 'form-group',
        default_args => { elements => { 'Text|Textarea|Select|File' => {
            attrs => { class => 'form-control' } } } },
        model_config => { resultset => 'Post' },
        attrs => { id => 'post-form' },
        elements => [
            { type => 'Text',
              name => 'title',
              label => 'Assunto',
              constraints => 'Required' },
            { type => 'Textarea',
              name => 'body',
              label => 'Corpo',
              constraints => 'Required' },
            { type => 'Submit',
              name => 'submit',
              value => 'Enviar' },
        ],
    };
}

__PACKAGE__->meta->make_immutable;

1;
