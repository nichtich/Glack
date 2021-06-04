package Glack;
use 5.14.1;
use IRI;
use Mojo::IOLoop;

our $VERSION = "0.01";

sub new {
    my ( $class, %options ) = @_;

    $options{port} ||= 1965;

    # TODO: cert, key

    bless \%options, $class;
}

sub run {
    my ( $self, $app ) = @_;

    Mojo::IOLoop->server(
        {
            port => $self->{port},

            # tls => 0, # TODO
            # tls_cert => $self->{cert_file},
            # tls_key  => $self->{key_file},
        } => sub {
            my ( $loop, $stream ) = @_;
            $stream->on(
                read => sub ($stream, $bytes) {
                    my ( $stream, $bytes );

                    # say "request: $bytes";
                    # $stream->write("...response...");
                }
            );
        }
    );
}

1;
__END__

=head1 NAME

Glack - Gemini server implementation

=head1 DESCRIPTION

Gemini server implementation based on L<GSGI>.

=head1 MODULES

=over

=item L<App::glackup>

=item L<Glack::Logger>

=back

=head1 SEE ALSO

The name Glack is a reference to L<Plack> but it also means "narrow valley" in Scottish.

See L<App::phoebe> for another Gemini server.

=head1 LICENSE

Copyright Jakob Voss, 2021-

GNU Affero General Public License.

=cut
