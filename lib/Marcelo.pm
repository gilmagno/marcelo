package Marcelo;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

use Catalyst qw/
    ConfigLoader
    Static::Simple
    StackTrace
    Authentication
    Authorization::Roles
    Session
    Session::Store::File
    Session::State::Cookie
/;

extends 'Catalyst';

our $VERSION = '0.01';

__PACKAGE__->config(
    name => 'Marcelo',
    # Disable deprecated behavior needed by old applications
    disable_component_resolution_regex_fallback => 1,
    enable_catalyst_header => 1, # Send X-Catalyst header
    'Plugin::Authentication' => {
	default => {
	    credential => {
		class => 'Password',
		password_field => 'password',
		password_type => 'self_check',
	    },
	    store => {
		class => 'DBIx::Class',
		user_model => 'DB::User',
                role_column => 'role',
	    },
	},
    },
);

__PACKAGE__->setup();

1;
