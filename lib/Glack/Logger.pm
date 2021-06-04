package Glack::Logger;
use v5.14.1;
use Carp;
use Scalar::Utils qw(reftype);

my %levels = (
    debug => 0,
    info  => 1,
    warn  => 2,
    error => 3,
    fatal => 4
);

sub new {
    my ( $class, $code, $min ) = @_;

    croak 'Logger must be a code reference' unless reftype $logger eq 'CODE';
    croak 'Level must be debug|info|warn|error|fatal'
      if $min and !exists $levels{$min};

    bless {
        code => $code,
        min  => $levels{ $min || 'debug' },
    }, $class;
}

sub debug {
    $_->[0]->{code}->( debug => $_[1] ) if $_->[0]{min} <= 0;
}

sub info {
    $_->[0]->{code}->( info => $_[1] ) if $_->[0]{min} <= 1;
}

sub warn {
    $_->[0]->{code}->( warn => $_[1] ) if $_->[0]{min} <= 2;
}

sub error {
    $_->[0]->{code}->( error => $_[1] ) if $_->[0]{min} <= 3;
}

sub fatal {
    $_->[0]->{code}->( fatal => $_[1] );
}

sub code {
    my ($self) = @_;
    return $self->{code};
}

1;
