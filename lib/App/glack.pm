package App::glack;
use 5.14.1;
use File::Spec ();
use Glack::Server;

sub new {
    my $class = shift;

    my $self = {};

    # -Ipath => -I path
    local @ARGV = map { /^-I(.+)/ ? ( '-I', $1 ) : $_ } @ARGV;

    require Getopt::Long;
    my $parser = Getopt::Long::Parser->new( config => ["no_ignore_case"] );
    $parser->getoptions(
        $self,          'app|a=s',    'port|p=i', 'host|o=s',
        'include|I=s@', 'key|l=s',    'cert|c=s', 'nossl|n',
        'reload|r',     'Reload|R=s', 'help|h',   'version|v',
    );

# TODO: cert file, -k|--insecure,-n|nossl
# TODO: if reload/Reload
#   => sub { $self->{loader} = "Restarter" },
#   => sub { $self->{loader} = "Restarter"; $self->loader->watch(split ",", $_[1]) },

    $self->{app} ||= $ARGV[0];

    bless $self, $class;
}

sub load_app {
    my ( $self, @args ) = @_;

    my $app = $args[0] || $self->{app};

    return sub { $app }
      if ref $app eq 'CODE';

    $app ||= 'app.glack';

    # TODO
    #require File::Basename;
    #my $lib = File::Basename::dirname($app) . "/lib";
    #$self->loader->watch($lib) if -e $lib;
    #$self->loader->watch($psgi)

    my $file = File::Spec->rel2abs($app);
    die "File not found: $file\n" unless -e $file;
    $app = _load_sandbox($file);
    die "Error while loading $file: $@" if $@;

    return $app;
}

# from Plack::Util
sub _load_sandbox {
    my $_file = shift;

    my $_package = $_file;
    $_package =~ s/([^A-Za-z0-9_])/sprintf("_%2x", unpack("C", $1))/eg;

    local $0    = $_file;    # so FindBin etc. works
    local @ARGV = ();        # Some frameworks might try to parse @ARGV

    return eval sprintf <<'EVAL', $_package;    ## no critic
package Glack::Sandbox::%s;
{
    my $app = do $_file;
    if ( !$app && ( my $error = $@ || $! )) { die $error; }
    $app;
}
EVAL
}

sub run {
    my $self = shift;

    return $self->new->run unless ref $self;

    if ( $self->{help} ) {
        require Pod::Usage;
        Pod::Usage::pod2usage(0);
    }

    if ( $self->{version} ) {
        require Glack;
        say $Glack::VERSION;
        exit;
    }

    my $app = $self->load_app( @_ ? @_ : $self->{app} );

    # TODO: cert/key/ssl
    my $server = Glack::Server->new;
    $server->run($app);
}

1;
__END__

=head1 NAME

App::glack - Implementation of glack command line application

=head1 SEE ALSO

See L<glack> for options.

Code derived from L<Plack::Runner> and L<Plack::Util>.

=cut
