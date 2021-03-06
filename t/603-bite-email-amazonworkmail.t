use strict;
use warnings;
use Test::More;
use lib qw(./lib ./blib/lib);
require './t/600-bite-email-code';

my $enginename = 'AmazonWorkMail';
my $enginetest = Sisimai::Bite::Email::Code->maketest;
my $isexpected = [
    { 'n' => '01', 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
    { 'n' => '02', 's' => qr/\A5[.]2[.]1\z/, 'r' => qr/filtered/,    'b' => qr/\A1\z/ },
    { 'n' => '03', 's' => qr/\A5[.]3[.]5\z/, 'r' => qr/systemerror/, 'b' => qr/\A1\z/ },
    { 'n' => '04', 's' => qr/\A5[.]2[.]2\z/, 'r' => qr/mailboxfull/, 'b' => qr/\A1\z/ },
    { 'n' => '05', 's' => qr/\A4[.]4[.]7\z/, 'r' => qr/expired/,     'b' => qr/\A1\z/ },
    { 'n' => '06', 's' => qr/\A5[.]2[.]2\z/, 'r' => qr/mailboxfull/, 'b' => qr/\A1\z/ },
    { 'n' => '07', 's' => qr/\A4[.]4[.]7\z/, 'r' => qr/expired/,     'b' => qr/\A1\z/ },
];

$enginetest->($enginename, $isexpected);
done_testing;

