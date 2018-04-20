package Marcelo::Model::DB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'Marcelo::Schema',
    connect_info => 'Marcelo',
);

=head1 NAME

Marcelo::Model::DB - Catalyst DBIC Schema Model

=head1 SYNOPSIS

See L<Marcelo>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<Marcelo::Schema>

=head1 GENERATED BY

Catalyst::Helper::Model::DBIC::Schema - 0.65

=head1 AUTHOR

sgrs

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
