use Plack::Builder;
# zuse Auth::Middleware;

my $app = sub {
    my $env = shift;
    my ($status, $headers, $body);

    require DerbyDues;
    eval {
        $body = DerbyDues::request($env);
        $status = 200;
    };
    $headers = [ 'Content-Type' => 'text/html'];
    if ($@) {
        $status = 500;
        $body = "ERROR!!! $@";
    }

    return [ $status, $headers, [$body] ];
};

# return Auth::Middleware::wrap($app);
