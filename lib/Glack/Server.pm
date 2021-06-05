package Glack::Server;
use 5.14.1;
use IO::Socket::INET;
use IO::Socket::SSL;
use Socket qw(IPPROTO_TCP);
use Glack::Logger;

use constant TCP_NODELAY      => eval { Socket::TCP_NODELAY };
use constant MAX_REQUEST_SIZE => 1024;

sub new {
    my ( $class, %args ) = @_;

    bless {
        host => $args{host} || 0,
        port => $args{port} || 1965,
        nossl     => $args{nossl},
        key_file  => $args{key},
        cert_file => $args{cert}
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
        Listen        => SOMAXCONN,
        LocalPort     => $self->{port},
        LocalAddr     => $self->{host},
        Proto         => 'tcp',
        ReuseAddr     => 1,
        SSL_key_file  => $self->{key_file},
        SSL_cert_file => $self->{cert_file},
    );

    # TODO: make SSL default
    my $class = $self->{ssl} ? 'IO::Socket::SSL' : 'IO::Socket::INET';

    $self->{socket} = $class->new(%args)
      or die "failed to listen to port $self->{port}: $!";
}

sub accept_loop {
    my ( $self, $app ) = @_;

    while (1) {
        local $SIG{PIPE} = 'IGNORE';
        if ( my $conn = $self->{socket}->accept ) {
            if ( defined TCP_NODELAY ) {
                $conn->setsockopt( IPPROTO_TCP, TCP_NODELAY, 1 )
                  or die "setsockopt(TCP_NODELAY) failed:$!";
            }

            my $env = { logger => Glack::Logger->new->{logger} };

            $self->handle_connection( $env, $conn, $app );
            $conn->close;
        }
    }
}

sub handle_connection {
    my ( $self, $env, $conn, $app ) = @_;

    my $req = '';
    my $res;
    my $log = Glack::Logger->new( $env->{logger} );

    $log->debug("connected...");

    # TODO: respect timeout and MAX_REQUEST_SIZE
    #local $/ = "\r\n";
    my $req = <$conn>;

    if ($req) {

        # TODO: validate URL
        chomp $req;
        $log->debug("Request URL: $req");
        $res = $app->( $req, $env );
    }
    else {
        $res = [ 59, 'BAD REQUEST' ];
    }

    if ( ref $res eq 'ARRAY' && $res->[0] =~ /^\d\d$/ ) {
        $res->[2] ||= [];
    }
    else {
        $res = [ 42, 'CGI ERROR' ];
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

=head1 SEE ALSO

Based on code of L<HTTP::Server::PSGI>.
See L<App::phoebe> for another Gemini server.

=cut
