use strict;
use warnings;
use Test::More;
use lib qw(./lib ./blib/lib);
require './t/600-bite-email-code';

my $enginename = 'Exim';
my $enginetest = Sisimai::Bite::Email::Code->maketest;
my $isexpected = [
    { 'n' => '01', 's' => qr/\A5[.]7[.]0\z/,      'r' => qr/blocked/,        'b' => qr/\A1\z/ },
    { 'n' => '02', 's' => qr/\A5[.][12][.]1\z/,   'r' => qr/userunknown/,    'b' => qr/\A0\z/ },
    { 'n' => '03', 's' => qr/\A5[.]7[.]0\z/,      'r' => qr/policyviolation/,'b' => qr/\A1\z/ },
    { 'n' => '04', 's' => qr/\A5[.]7[.]0\z/,      'r' => qr/blocked/,        'b' => qr/\A1\z/ },
    { 'n' => '05', 's' => qr/\A5[.]1[.]1\z/,      'r' => qr/userunknown/,    'b' => qr/\A0\z/ },
    { 'n' => '06', 's' => qr/\A4[.]0[.]\d+\z/,    'r' => qr/expired/,        'b' => qr/\A1\z/ },
    { 'n' => '07', 's' => qr/\A4[.]0[.]\d+\z/,    'r' => qr/mailboxfull/,    'b' => qr/\A1\z/ },
    { 'n' => '08', 's' => qr/\A4[.]0[.]\d+\z/,    'r' => qr/expired/,        'b' => qr/\A1\z/ },
    { 'n' => '09', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/hostunknown/,    'b' => qr/\A0\z/ },
    { 'n' => '10', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/suspend/,        'b' => qr/\A1\z/ },
    { 'n' => '11', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/onhold/,         'b' => qr/\A0\z/ },
    { 'n' => '12', 's' => qr/\A[45][.]0[.]\d+\z/, 'r' => qr/(?:hostunknown|expired|undefined)/, 'b' => qr/\d\z/ },
    { 'n' => '13', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/(?:onhold|undefined|mailererror)/,  'b' => qr/\d\z/ },
    { 'n' => '14', 's' => qr/\A4[.]0[.]\d+\z/,    'r' => qr/expired/,        'b' => qr/\A1\z/ },
    { 'n' => '15', 's' => qr/\A5[.]4[.]3\z/,      'r' => qr/systemerror/,    'b' => qr/\A1\z/ },
    { 'n' => '16', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/systemerror/,    'b' => qr/\A1\z/ },
    { 'n' => '17', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/mailboxfull/,    'b' => qr/\A1\z/ },
    { 'n' => '18', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/hostunknown/,    'b' => qr/\A0\z/ },
    { 'n' => '19', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/networkerror/,   'b' => qr/\A1\z/ },
    { 'n' => '20', 's' => qr/\A4[.]0[.]\d+\z/,    'r' => qr/(?:expired|systemerror)/, 'b' => qr/\A1\z/ },
    { 'n' => '21', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/expired/,        'b' => qr/\A1\z/ },

    { 'n' => '23', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/userunknown/,    'b' => qr/\A0\z/ },
    { 'n' => '24', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/filtered/,       'b' => qr/\A1\z/ },
    { 'n' => '25', 's' => qr/\A4[.]0[.]\d+\z/,    'r' => qr/expired/,        'b' => qr/\A1\z/ },
    { 'n' => '26', 's' => qr/\A5[.]0[.]0\z/,      'r' => qr/mailererror/,    'b' => qr/\A1\z/ },
    { 'n' => '27', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/blocked/,        'b' => qr/\A1\z/ },
    { 'n' => '28', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/mailererror/,    'b' => qr/\A1\z/ },
    { 'n' => '29', 's' => qr/\A5[.]0[.]\d+\z/,    'r' => qr/blocked/,        'b' => qr/\A1\z/ },
    { 'n' => '30', 's' => qr/\A5[.]7[.]1\z/,      'r' => qr/securityerror/,  'b' => qr/\A1\z/ },
];

$enginetest->($enginename, $isexpected);
done_testing;

