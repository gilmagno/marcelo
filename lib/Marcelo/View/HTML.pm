package Marcelo::View::HTML;
use Moose;
use namespace::autoclean;
use Text::Markdown ();

extends 'Catalyst::View::TT';

__PACKAGE__->config(
    TEMPLATE_EXTENSION => '.tt',
    render_die => 1,
    ENCODING => 'utf-8',
    WRAPPER => 'wrapper.tt',
    expose_methods => [qw/markdown/],
);

sub markdown { Text::Markdown::markdown $_[2] if $_[2] }

1;
