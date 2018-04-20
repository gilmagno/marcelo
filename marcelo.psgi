use strict;
use warnings;

use Marcelo;

my $app = Marcelo->apply_default_middlewares(Marcelo->psgi_app);
$app;

