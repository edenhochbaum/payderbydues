package PayDerbyDues::View;

use File::Slurp;
use Text::Handlebars;

my $templatedir = "/home/ec2-user/payderbydues/www/handlebarstemplates";

# render - render a Handlebars template file and return a plack response
# parameters:
#    $filename - the name of the template to render, without the actual
#                path to the directory or the .hbs extension
#    $vars - the template variables, passed to Handlebars
sub render {
    my ($filename, $vars) = @_;

    my $handlebars = Text::Handlebars->new();
    my $template = File::Slurp::read_file("$templatedir/$filename.hbs");
    my $res = Plack::Response->new(200);
    $res->content_type('text/html');
    $res->body($handlebars->render_string($template, $vars));

    return $res->finalize();
}

# render_layout - render layout.hbs with the given file as its contents
# This function renders the handlebars template corresponding to the given
# filename, then renders layout.hbs with the rendered template being passed
# as the "container" variable. Each rendering gets its own set of variables.
# parameters:
#     $filename - the name of the template to render, without the path or
#                 the .hbs extension.
#     $layoutvars - a hashref of variables to pass to Handlebars when
#                   rendering layout.hbs
#     $contentvars - a hashref of variables to pass to Handlebars when
#                    rendering the content template
sub render_layout {
    my ($filename, $layoutvars, $contentvars) = @_;

    my $handlebars = Text::Handlebars->new();
    my $content = File::Slurp::read_file("$templatedir/$filename.hbs");
    my $container_contents = $handlebars->render_string($content, $contentvars);

    return render('layout', {
        %$layoutvars,
        container => $container_contents
    });
}

1;
