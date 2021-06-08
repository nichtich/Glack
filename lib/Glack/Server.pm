package Glack::Server;
use 5.14.1;
use IO::Socket::INET;
use IO::Socket::SSL;
use Socket qw(IPPROTO_TCP);
use URI;
use Glack::Logger;

use constant TCP_NODELAY => eval { Socket::TCP_NODELAY };

sub new {
    my ( $class, %args ) = @_;

    bless {
        host => $args{host} || 0,
        port => $args{port} || 1965,
        nossl     => $args{nossl},
        key_file  => $args{key},
        cert_file => $args{cert},
        logger    => $args{logger} || Glack::Logger->new,
    }, $class;
}

sub run {
    my ( $self, $app ) = @_;
    $self->setup();
    $self->accept_loop($app);
}

sub setup {
    my $self = shift;

    my %args = (
        Listen          => SOMAXCONN,
        LocalPort       => $self->{port},
        LocalAddr       => $self->{host},
        Proto           => 'tcp',
        ReuseAddr       => 1,
        SSL_key_file    => $self->{key_file},
        SSL_cert_file   => $self->{cert_file},
        SSL_verify_mode => SSL_VERIFY_PEER,

        # TODO: client certificates
        # SSL_client_ca_file => ...
        # SSL_keepSocketOnError => 1
    );

    my $class = $self->{nossl} ? 'IO::Socket::INET' : 'IO::Socket::SSL';

    $self->{socket} = $class->new(%args)
      or die "failed to listen at port $self->{port}: $!\n";
}

sub accept_loop {
    my ( $self, $app ) = @_;

    say "Listening at " . ( $self->{nossl} ? '' : 'gemini://' ) . join ':',
      $self->{host}, $self->{port};

    while (1) {
        local $SIG{PIPE} = 'IGNORE';
        if ( my $conn = $self->{socket}->accept ) {
            if ( defined TCP_NODELAY ) {
                $conn->setsockopt( IPPROTO_TCP, TCP_NODELAY, 1 )
                  or die "setsockopt(TCP_NODELAY) failed: $!";
            }

            my $env = {
                host        => $self->{host},
                port        => $self->{port},
                remote_host => $conn->peerhost,
                remote_port => $conn->peerport || 0,
                logger      => $self->{logger},
            };

            $self->handle_connection( $env, $conn, $app );
            $conn->close;
        }
    }
}

sub handle_connection {
    my ( $self, $env, $conn, $app ) = @_;

    my $res;
    my $log = $env->{logger};

    my $req = <$conn>;
    my $url = URI->new($req);
    if ( !$url->scheme ) {
        $res = [ 59, '🐁 Request must be an absolute URL with scheme' ];
    }
    elsif ( length $req > 1024 ) {
        $res = [ 59, '🐍 Request length must not exceed 1024 bytes' ];
    }
    else {
        $res = eval { $app->( $url, $env ) };
        $log->error($@) if $@;
    }

    if ( ref $res eq 'ARRAY' && $res->[0] =~ /^\d\d$/ ) {
        $res->[2] ||= [];
    }
    else {
        $res = [ 42, '🐋 CGI error' ];
    }

    my $status = $res->[0];
    my $meta   = $res->[1] || '';
    my $body   = $res->[2] || [];

    if ( ref $body eq 'ARRAY' ) {
        $body = join "\r\n", @$body;
    }
    else {
        $body = "$body";
    }

    $conn->write("$status $meta\r\n$body");
}

1;
__END__

=head1 NAME

Glack - Gemini server implementation

=head1 DESCRIPTION

Glack::Server implements a simple, single-process L<GSGI> compatible Gemini
protocol server.

=head1 CONFIGURATION

=over

=item host

Set to C<0> by default.

=item port

Set to 1965 by default.

=item key

SSL key file.

=item cert

SSL certificate file.

=item nossl

Can be used to disable SSL (for testing).

=item logger

=back

=head1 SEE ALSO

Based on code of L<HTTP::Server::PSGI>.

See L<App::phoebe> for another Gemini server.

=cut
