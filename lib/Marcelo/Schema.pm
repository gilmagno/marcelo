use utf8;
package Marcelo::Schema;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use Moose;
use MooseX::MarkAsMethods autoclean => 1;
extends 'DBIx::Class::Schema';

__PACKAGE__->load_namespaces;


# Created by DBIx::Class::Schema::Loader v0.07045 @ 2018-04-12 15:24:19
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:yCYqzFrqGQj4uSoc8xClcg

__PACKAGE__->load_components('Schema::Config');

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

1;
