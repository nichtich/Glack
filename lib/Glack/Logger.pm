package Glack::Logger;
use v5.14.1;
use Carp;
use Scalar::Util qw(reftype);

my %levels = (
    debug => 0,
    info  => 1,
    warn  => 2,
    error => 3,
    fatal => 4
);

sub new {
    my ( $class, $logger, $min ) = @_;

    $logger ||= sub {
        my $level   = uc $_[0]->{level};
        my $message = $_[0]->{message};
        say STDERR "$level: $message";
    };

    croak 'Logger must be a logger reference' unless reftype $logger eq 'CODE';
    croak 'Level must be debug|info|warn|error|fatal'
      if $min and !exists $levels{$min};

    bless {
        logger => $logger,
        min    => $levels{ $min || 'debug' },
    }, $class;
}

sub debug {
    $_[0]->{logger}->( { level => 'debug', message => $_[1] } )
      if $_->[0]{min} <= 0;
}

sub info {
    $_[0]->{logger}->( { level => 'info', message => $_[1] } )
      if $_->[0]{min} <= 1;
}

sub warn {
    $_[0]->{logger}->( { level => 'warn', message => $_[1] } )
      if $_->[0]{min} <= 2;
}

sub error {
    $_[0]->{logger}->( { level => 'error', message => $_[1] } )
      if $_->[0]{min} <= 3;
}

sub fatal {
    $_[0]->{logger}->( { level => 'fatal', message => $_[1] } );
}

1;
__END__

=head1 NAME

Glack::Logger - Utility class for logging

=cut
