package GSGI;
use 5.14.1;

our $VERSION = "0.01";

1;
__END__

=encoding utf-8

=head1 NAME

GSGI - Gemini Protocol Server Gateway Interface Specification

=head1 DESCRIPTION

GSGI is like L<PSGI> but for L<Gemini Protocol|https://gemini.circumlunar.space/docs/specification.html>.

=head1 SPECIFICATION

=head2 Application

A GSGI application is a Perl code reference. It takes at least one argument, the request string, and returns an array reference with the response object.

  my $app = sub {
    my $req = shift;
    return [
      20, 'text/gemini; charset=utf-8',
      [
        '# Welcome',
        'Hello, World!'
      ]
    ]
  }

An application MAY take a hash reference as second argument. The hash reference contains the following keys:

=over

=item logger

a code reference to log messages. A message MUST be passed as hash reference with at least two keys:

=over

=item level

One of the strings debug, info, warn, error and fatal.

=item message

A plain string or a scalar variable that stringifies.

=back

=back

=head2 Server

A GSGI server is a program that routes complete Gemini requests to GSGI applications and returns Gemini responses.

=head2 Request string

A request string is a UTF-8 encoded string, of maximum length 1024 bytes. The request string can either be a complete Gemini request or an abbreviated request.

A complete Gemini request MUST be an absolute URL, including a scheme. 

An abbreviated request MUST be a string can be transformed into a complete Gemini request by prepending a prefix.

=head2 Response object

Applications MUST return a resonse as two or three element array reference. The response array reference consists of the following elements:

=over

=item Status

A valid Gemini status code given as integer.

=item Meta

A UTF-8 encoded string of maximum length 1024 bytes.

=item Body

An optional response body given either as array reference or as code reference. The body element SHOULD not be given if the status is not in the SUCCESS range (C<2x>).

If the body is an array reference, its elements MUST be strings. 

If the body is a code reference, it MUST return a string.

=back

=head1 OPEN ISSUES

Applications may want to know about client certificates.

=head1 LICENSE

Copyright Jakob Voss, 2021-

This document is licensed under the Creative Commons license by-sa.

=cut
