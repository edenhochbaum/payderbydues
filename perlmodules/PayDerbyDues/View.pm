package PayDerbyDues::View;

use File::Slurp;
use Text::Handlebars;

sub render {
    my ($filename, $vars) = @_;

    my $handlebars = Text::Handlebars->new();
    my $template = File::Slurp::read_file("www/handlebarstemplates/$filename");

    return $handlebars->render_string($template, $vars);
}

1;
