package PayDerbyDues::Constants;

use strict;
use warnings;

# TODO: migrate to real constants

# content-type headers
our $HTML_CONTENT_TYPE_HEADER = [ 'Content-Type' => 'text/html' ];
our $PLAIN_CONTENT_TYPE_HEADER = [ 'Content-Type' => 'text/plain' ];

# http status codes
our $HTTP_SUCCESS_STATUS = 200;
our $HTTP_NOT_FOUND_STATUS = 404;
our $HTTP_INTERNAL_ERROR_STATUS = 500;

1;
