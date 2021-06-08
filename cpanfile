requires 'perl', '5.014001';
requires 'IO::Socket::SSL';
requires 'URI';

on 'test' => sub {
    requires 'Test::More', '0.98';
};

