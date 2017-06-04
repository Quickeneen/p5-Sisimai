use strict;
use Test::More;
use lib qw(./lib ./blib/lib);
use Sisimai::Data;
use Sisimai::Mail;
use Sisimai::Message;
use Module::Load;

my $DebugOnlyTo = '';
my $MethodNames = {
    'class'  => ['description', 'headerlist', 'scan', 'pattern', 'DELIVERYSTATUS'],
    'object' => [],
};
my $MTAChildren = {
    'Activehunter' => {
        '01' => { 's' => qr/\A5[.]1[.]1\z/,   'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/filtered/,    'b' => qr/\A1\z/ },
    },
    'ApacheJames' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/filtered/,    'b' => qr/\A1\z/ },
    },
    'Courier' => {
        '01' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/,   'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.]0[.]0\z/, 'r' => qr/filtered/,      'b' => qr/\A1\z/ },
        '03' => { 's' => qr/\A5[.]7[.]1\z/, 'r' => qr/blocked/,       'b' => qr/\A1\z/ },
        '04' => { 's' => qr/\A5[.]0[.]0\z/, 'r' => qr/hostunknown/,   'b' => qr/\A0\z/ },
    },
    'Domino' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
    },
    'Exchange2003' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '03' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '04' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/filtered/,    'b' => qr/\A1\z/ },
        '05' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '06' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
    },
    'Exchange2007' => {
        '01' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.]2[.]3\z/, 'r' => qr/mesgtoobig/,  'b' => qr/\A1\z/ },
        '03' => { 's' => qr/\A5[.]2[.]2\z/, 'r' => qr/mailboxfull/, 'b' => qr/\A1\z/ },
    },
    'Exim' => {
        '01' => { 's' => qr/\A5[.]7[.]0\z/,    'r' => qr/blocked/,        'b' => qr/\A1\z/ },
        '02' => { 's' => qr/\A5[.][12][.]1\z/, 'r' => qr/userunknown/,    'b' => qr/\A0\z/ },
        '03' => { 's' => qr/\A5[.]7[.]0\z/,    'r' => qr/policyviolation/,'b' => qr/\A1\z/ },
        '04' => { 's' => qr/\A5[.]7[.]0\z/,    'r' => qr/blocked/,        'b' => qr/\A1\z/ },
        '05' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/userunknown/,    'b' => qr/\A0\z/ },
        '06' => { 's' => qr/\A4[.]0[.]\d+\z/,  'r' => qr/expired/,        'b' => qr/\A1\z/ },
        '07' => { 's' => qr/\A4[.]0[.]\d+\z/,  'r' => qr/mailboxfull/,    'b' => qr/\A1\z/ },
        '08' => { 's' => qr/\A4[.]0[.]\d+\z/,  'r' => qr/expired/,        'b' => qr/\A1\z/ },
        '09' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/hostunknown/,    'b' => qr/\A0\z/ },
        '10' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/suspend/,        'b' => qr/\A1\z/ },
        '11' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/onhold/,         'b' => qr/\A0\z/ },
        '12' => { 's' => qr/\A[45][.]0[.]\d+\z/, 'r' => qr/(?:hostunknown|expired|undefined)/,'b' => qr/\d\z/ },
        '13' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/(?:onhold|undefined|mailererror)/,   'b' => qr/\d\z/ },
        '14' => { 's' => qr/\A4[.]0[.]\d+\z/,  'r' => qr/expired/,        'b' => qr/\A1\z/ },
        '15' => { 's' => qr/\A5[.]4[.]3\z/,    'r' => qr/systemerror/,    'b' => qr/\A1\z/ },
        '16' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/systemerror/,    'b' => qr/\A1\z/ },
        '17' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/mailboxfull/,    'b' => qr/\A1\z/ },
        '18' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/hostunknown/,    'b' => qr/\A0\z/ },
        '19' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/networkerror/,   'b' => qr/\A1\z/ },
        '20' => { 's' => qr/\A4[.]0[.]\d+\z/,  'r' => qr/(?:expired|systemerror)/,    'b' => qr/\A1\z/ },
        '21' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/expired/,        'b' => qr/\A1\z/ },
        '23' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/userunknown/,    'b' => qr/\A0\z/ },
        '24' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/filtered/,       'b' => qr/\A1\z/ },
        '25' => { 's' => qr/\A4[.]0[.]\d+\z/,  'r' => qr/expired/,        'b' => qr/\A1\z/ },
        '26' => { 's' => qr/\A5[.]0[.]0\z/,    'r' => qr/mailererror/,    'b' => qr/\A1\z/ },
        '27' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/blocked/,        'b' => qr/\A1\z/ },
        '28' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/mailererror/,    'b' => qr/\A1\z/ },
        '29' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/blocked/,        'b' => qr/\A1\z/ },
        '30' => { 's' => qr/\A5[.]7[.]1\z/,    'r' => qr/securityerror/,  'b' => qr/\A1\z/ },
    },
    'IMailServer' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/mailboxfull/, 'b' => qr/\A1\z/ },
        '03' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '04' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/expired/,     'b' => qr/\A1\z/ },
        '05' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/undefined/,   'b' => qr/\A0\z/ },
    },
    'InterScanMSS' => {
        '01' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/,   'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/,   'b' => qr/\A0\z/ },
    },
    'MailFoundry' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/filtered/,    'b' => qr/\A1\z/ },
        '02' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/mailboxfull/, 'b' => qr/\A1\z/ },
    },
    'MailMarshalSMTP' => {
        '01' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
    },
    'McAfee' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/userunknown/,    'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/userunknown/,    'b' => qr/\A0\z/ },
        '03' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/userunknown/,    'b' => qr/\A0\z/ },
    },
    'MessagingServer' => {
        '01' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/,   'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.]2[.]0\z/, 'r' => qr/mailboxfull/,   'b' => qr/\A1\z/ },
        '03' => { 's' => qr/\A5[.]7[.]1\z/, 'r' => qr/filtered/,      'b' => qr/\A1\z/ },
        '04' => { 's' => qr/\A5[.]2[.]2\z/, 'r' => qr/mailboxfull/,   'b' => qr/\A1\z/ },
        '05' => { 's' => qr/\A5[.]4[.]4\z/, 'r' => qr/hostunknown/,   'b' => qr/\A0\z/ },
        '06' => { 's' => qr/\A5[.]2[.]1\z/, 'r' => qr/filtered/,      'b' => qr/\A1\z/ },
        '07' => { 's' => qr/\A4[.]4[.]7\z/, 'r' => qr/expired/,       'b' => qr/\A1\z/ },
    },
    'mFILTER' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/filtered/,   'b' => qr/\A1\z/ },
        '02' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/userunknown/,'b' => qr/\A0\z/ },
        '03' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/filtered/,   'b' => qr/\A1\z/ },
    },
    'MXLogic' => {
        '01' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/userunknown/,    'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/userunknown/,    'b' => qr/\A0\z/ },
        '03' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/filtered/,       'b' => qr/\A1\z/ },
    },
    'Notes' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/onhold/,      'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '03' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '04' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/networkerror/,'b' => qr/\A1\z/ },
    },
    'OpenSMTPD' => {
        '01' => { 's' => qr/\A5[.]1[.]1\z/,        'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.][12][.][12]\z/,  'r' => qr/(?:userunknown|mailboxfull)/,'b' => qr/\d\z/ },
        '03' => { 's' => qr/\A5[.]0[.]\d+\z/,      'r' => qr/hostunknown/, 'b' => qr/\A0\z/ },
        '04' => { 's' => qr/\A5[.]0[.]\d+\z/,      'r' => qr/networkerror/,'b' => qr/\A1\z/ },
        '05' => { 's' => qr/\A5[.]0[.]\d+\z/,      'r' => qr/expired/,     'b' => qr/\A1\z/ },
        '06' => { 's' => qr/\A5[.]0[.]\d+\z/,      'r' => qr/expired/,     'b' => qr/\A1\z/ },
    },
    'Postfix' => {
        '01' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/mailererror/,'b' => qr/\A1\z/ },
        '02' => { 's' => qr/\A5[.][12][.]1\z/, 'r' => qr/(?:filtered|userunknown)/, 'b' => qr/\d\z/ },
        '03' => { 's' => qr/\A5[.]0[.]0\z/,    'r' => qr/filtered/,   'b' => qr/\A1\z/ },
        '04' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/userunknown/,'b' => qr/\A0\z/ },
        '05' => { 's' => qr/\A4[.]1[.]1\z/,    'r' => qr/userunknown/,'b' => qr/\A0\z/ },
        '06' => { 's' => qr/\A5[.]4[.]4\z/,    'r' => qr/hostunknown/,'b' => qr/\A0\z/ },
        '07' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/filtered/,   'b' => qr/\A1\z/ },
        '08' => { 's' => qr/\A4[.]4[.]1\z/,    'r' => qr/expired/,    'b' => qr/\A1\z/ },
        '09' => { 's' => qr/\A4[.]3[.]2\z/,    'r' => qr/toomanyconn/,'b' => qr/\A1\z/ },
        '10' => { 's' => qr/\A5[.]1[.]8\z/,    'r' => qr/rejected/,   'b' => qr/\A1\z/ },
        '11' => { 's' => qr/\A5[.]1[.]8\z/,    'r' => qr/rejected/,   'b' => qr/\A1\z/ },
        '12' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/userunknown/,'b' => qr/\A0\z/ },
        '13' => { 's' => qr/\A5[.]2[.][12]\z/, 'r' => qr/(?:userunknown|mailboxfull)/, 'b' => qr/\d\z/ },
        '14' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/userunknown/,'b' => qr/\A0\z/ },
        '15' => { 's' => qr/\A4[.]4[.]1\z/,    'r' => qr/expired/,    'b' => qr/\A1\z/ },
        '16' => { 's' => qr/\A5[.]1[.]6\z/,    'r' => qr/hasmoved/,   'b' => qr/\A0\z/ },
        '17' => { 's' => qr/\A5[.]4[.]4\z/,    'r' => qr/networkerror/, 'b' => qr/\A1\z/ },
        '18' => { 's' => qr/\A5[.]7[.]1\z/,    'r' => qr/norelaying/, 'b' => qr/\A1\z/ },
        '19' => { 's' => qr/\A5[.]0[.]0\z/,    'r' => qr/blocked/,    'b' => qr/\A1\z/ },
        '20' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/onhold/,     'b' => qr/\d\z/ },
        '21' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/networkerror/, 'b' => qr/\A1\z/ },
        '22' => { 's' => qr/\A4[.]0[.]0\z/,    'r' => qr/systemerror/,'b' => qr/\A1\z/ },
        '23' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/userunknown/,'b' => qr/\A0\z/ },
        '24' => { 's' => qr/\A5[.]0[.]0\z/,    'r' => qr/userunknown/,'b' => qr/\A0\z/ },
        '25' => { 's' => qr/\A4[.]4[.]1\z/,    'r' => qr/expired/,    'b' => qr/\A1\z/ },
        '26' => { 's' => qr/\A5[.]4[.]4\z/,    'r' => qr/hostunknown/,'b' => qr/\A0\z/ },
        '27' => { 's' => qr/\A5[.]1[.]1\z/,    'r' => qr/userunknown/,'b' => qr/\A0\z/ },
        '28' => { 's' => qr/\A5[.]7[.]1\z/,    'r' => qr/policyviolation/, 'b' => qr/\A1\z/ },
        '29' => { 's' => qr/\A5[.]7[.]1\z/,    'r' => qr/policyviolation/, 'b' => qr/\A1\z/ },
    },
    'qmail' => {
        '01' => { 's' => qr/\A5[.]5[.]0\z/,    'r' => qr/userunknown/,'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.][12][.]1\z/, 'r' => qr/(?:userunknown|filtered)/, 'b' => qr/\d\z/ },
        '03' => { 's' => qr/\A5[.]7[.]1\z/,    'r' => qr/rejected/,   'b' => qr/\A1\z/ },
        '04' => { 's' => qr/\A5[.]0[.]0\z/,    'r' => qr/blocked/,    'b' => qr/\A1\z/ },
        '05' => { 's' => qr/\A4[.]4[.]3\z/,    'r' => qr/systemerror/,'b' => qr/\A1\z/ },
        '06' => { 's' => qr/\A4[.]2[.]2\z/,    'r' => qr/mailboxfull/,'b' => qr/\A1\z/ },
        '07' => { 's' => qr/\A4[.]4[.]1\z/,    'r' => qr/networkerror/,'b' => qr/\A1\z/ },
        '08' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/mailboxfull/,'b' => qr/\A1\z/ },
        '09' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/undefined/,  'b' => qr/\A0\z/ },
        '10' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/hostunknown/,'b' => qr/\A0\z/ },
        '11' => { 's' => qr/\A5[.]7[.]1\z/,    'r' => qr/norelaying/, 'b' => qr/\A1\z/ },
        '12' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/hostunknown/,'b' => qr/\A0\z/ },
    },
    'Sendmail' => {
        '01' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/,   'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.][12][.]1\z/, 'r' => qr/(?:userunknown|filtered)/, 'b' => qr/\d\z/ },
        '03' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/,   'b' => qr/\A0\z/ },
        '04' => { 's' => qr/\A5[.]1[.]8\z/, 'r' => qr/rejected/,      'b' => qr/\A1\z/ },
        '05' => { 's' => qr/\A5[.]2[.]3\z/, 'r' => qr/exceedlimit/,   'b' => qr/\A1\z/ },
        '06' => { 's' => qr/\A5[.]6[.]9\z/, 'r' => qr/contenterror/,  'b' => qr/\A1\z/ },
        '07' => { 's' => qr/\A5[.]7[.]1\z/, 'r' => qr/norelaying/,    'b' => qr/\A1\z/ },
        '08' => { 's' => qr/\A4[.]7[.]1\z/, 'r' => qr/blocked/,       'b' => qr/\A1\z/ },
        '09' => { 's' => qr/\A5[.]7[.]9\z/, 'r' => qr/policyviolation/, 'b' => qr/\A1\z/ },
        '10' => { 's' => qr/\A4[.]7[.]1\z/, 'r' => qr/blocked/,       'b' => qr/\A1\z/ },
        '11' => { 's' => qr/\A4[.]4[.]7\z/, 'r' => qr/expired/,       'b' => qr/\A1\z/ },
        '12' => { 's' => qr/\A4[.]4[.]7\z/, 'r' => qr/expired/,       'b' => qr/\A1\z/ },
        '13' => { 's' => qr/\A5[.]3[.]0\z/, 'r' => qr/systemerror/,   'b' => qr/\A1\z/ },
        '14' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/,   'b' => qr/\A0\z/ },
        '15' => { 's' => qr/\A5[.]1[.]2\z/, 'r' => qr/hostunknown/,   'b' => qr/\A0\z/ },
        '16' => { 's' => qr/\A5[.]5[.]0\z/, 'r' => qr/blocked/,       'b' => qr/\A1\z/ },
        '17' => { 's' => qr/\A5[.]1[.]6\z/, 'r' => qr/hasmoved/,      'b' => qr/\A0\z/ },
        '18' => { 's' => qr/\A5[.]0[.]0\z/, 'r' => qr/mailererror/,   'b' => qr/\A1\z/ },
        '19' => { 's' => qr/\A5[.]2[.]0\z/, 'r' => qr/filtered/,      'b' => qr/\A1\z/ },
        '20' => { 's' => qr/\A5[.]4[.]6\z/, 'r' => qr/networkerror/,  'b' => qr/\A1\z/ },
        '21' => { 's' => qr/\A4[.]4[.]7\z/, 'r' => qr/blocked/,       'b' => qr/\A1\z/ },
        '22' => { 's' => qr/\A5[.]1[.]6\z/, 'r' => qr/hasmoved/,      'b' => qr/\A0\z/ },
        '23' => { 's' => qr/\A5[.]7[.]1\z/, 'r' => qr/spamdetected/,  'b' => qr/\A1\z/ },
        '24' => { 's' => qr/\A5[.]1[.]2\z/, 'r' => qr/hostunknown/,   'b' => qr/\A0\z/ },
        '25' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/,   'b' => qr/\A0\z/ },
        '26' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/,   'b' => qr/\A0\z/ },
        '27' => { 's' => qr/\A5[.]0[.]0\z/, 'r' => qr/filtered/,      'b' => qr/\A1\z/ },
        '28' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/,   'b' => qr/\A0\z/ },
        '29' => { 's' => qr/\A4[.]5[.]0\z/, 'r' => qr/expired/,       'b' => qr/\A1\z/ },
        '30' => { 's' => qr/\A4[.]4[.]7\z/, 'r' => qr/expired/,       'b' => qr/\A1\z/ },
        '31' => { 's' => qr/\A5[.]7[.]0\z/, 'r' => qr/securityerror/, 'b' => qr/\A1\z/ },
        '32' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/,   'b' => qr/\A0\z/ },
        '33' => { 's' => qr/\A5[.]7[.]1\z/, 'r' => qr/blocked/,       'b' => qr/\A1\z/ },
        '34' => { 's' => qr/\A5[.]7[.]0\z/, 'r' => qr/securityerror/, 'b' => qr/\A1\z/ },
        '35' => { 's' => qr/\A5[.]7[.]13\z/, 'r' => qr/suspend/,      'b' => qr/\A1\z/ },
        '36' => { 's' => qr/\A5[.]7[.]1\z/, 'r' => qr/blocked/,       'b' => qr/\A1\z/ },
        '37' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/,   'b' => qr/\A0\z/ },
        '38' => { 's' => qr/\A5[.]7[.]1\z/, 'r' => qr/spamdetected/,  'b' => qr/\A1\z/ },
        '39' => { 's' => qr/\A4[.]4[.]5\z/, 'r' => qr/systemfull/,    'b' => qr/\A1\z/ },
        '40' => { 's' => qr/\A5[.]2[.]0\z/, 'r' => qr/filtered/,      'b' => qr/\A1\z/ },
        '41' => { 's' => qr/\A5[.]0[.]0\z/, 'r' => qr/filtered/,      'b' => qr/\A1\z/ },
        '42' => { 's' => qr/\A5[.]1[.]2\z/, 'r' => qr/hostunknown/,   'b' => qr/\A0\z/ },
        '43' => { 's' => qr/\A5[.]7[.]1\z/, 'r' => qr/policyviolation/, 'b' => qr/\A1\z/ },
    },
    'SurfControl' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/filtered/,    'b' => qr/\A1\z/ },
        '02' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/systemerror/, 'b' => qr/\A1\z/ },
        '03' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/systemerror/, 'b' => qr/\A1\z/ },
    },
    'V5sendmail' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/expired/,     'b' => qr/\A1\z/ },
        '02' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/hostunknown/, 'b' => qr/\A0\z/ },
        '03' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '04' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/hostunknown/, 'b' => qr/\A0\z/ },
        '05' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/(?:hostunknown|blocked|userunknown)/, 'b' => qr/\d\z/ },
        '06' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/norelaying/,  'b' => qr/\A1\z/ },
        '07' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/(?:hostunknown|blocked|userunknown)/, 'b' => qr/\d\z/ },
    },
    'X1' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/filtered/,    'b' => qr/\A1\z/ },
        '02' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/filtered/,    'b' => qr/\A1\z/ },
    },
    'X2' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/filtered/,    'b' => qr/\A1\z/ },
        '02' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/(?:filtered|suspend)/, 'b' => qr/\A1\z/ },
        '03' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/expired/,     'b' => qr/\A1\z/ },
        '04' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/mailboxfull/, 'b' => qr/\A1\z/ },
        '05' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/suspend/,     'b' => qr/\A1\z/ },
    },
    'X3' => {
        '01' => { 's' => qr/\A5[.]3[.]0\z/,    'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '02' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/expired/,     'b' => qr/\A1\z/ },
        '03' => { 's' => qr/\A5[.]3[.]0\z/,    'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '04' => { 's' => qr/\A5[.]0[.]\d+\z/,  'r' => qr/undefined/,   'b' => qr/\A0\z/ },
    },
    'X4' => {
        '01' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/mailboxfull/, 'b' => qr/\A1\z/ },
        '02' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/mailboxfull/, 'b' => qr/\A1\z/ },
        '03' => { 's' => qr/\A5[.]1[.]1\z/,   'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '04' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '05' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
        '06' => { 's' => qr/\A5[.]0[.]\d+\z/, 'r' => qr/mailboxfull/, 'b' => qr/\A1\z/ },
        '07' => { 's' => qr/\A4[.]4[.]1\z/,   'r' => qr/networkerror/,'b' => qr/\A1\z/ },
    },
    'X5' => {
        '01' => { 's' => qr/\A5[.]1[.]1\z/, 'r' => qr/userunknown/, 'b' => qr/\A0\z/ },
    }
};

for my $x ( keys %$MTAChildren ) {
    # Check each MTA module
    my $M = 'Sisimai::MTA::'.$x;
    my $v = undef;
    my $n = 0;
    my $c = 0;
    my $d = 0;

    Module::Load::load($M);
    use_ok $M;
    can_ok $M, @{ $MethodNames->{'class'} };

    MAKE_TEST: {
        $v = $M->description; ok $v, $x.'->description = '.$v;
        $v = $M->smtpagent;   ok $v, $x.'->smtpagent = '.$v;
        $v = $M->pattern;     ok keys %$v; isa_ok $v, 'HASH';

        $M->scan, undef, $M.'->scan = undef';

        PARSE_EACH_MAIL: for my $i ( 1 .. scalar keys %{ $MTAChildren->{ $x } } ) {
            # Open email in set-of-emails/ directory
            if( length $DebugOnlyTo ) {
                $c = 1;
                next unless $DebugOnlyTo eq sprintf("%s-%02d", lc($x), $i);
            }

            my $emailfn = sprintf("./set-of-emails/maildir/bsd/mta-%s-%02d.eml", lc($x), $i);
            my $mailbox = Sisimai::Mail->new($emailfn);

            $n = sprintf("%02d", $i);
            next unless defined $mailbox;
            next unless $MTAChildren->{ $x }->{ $n };
            ok -f $emailfn, sprintf("[%s] %s/email = %s", $n, $M,$emailfn);

            while( my $r = $mailbox->read ) {
                # Parse each email in set-of-emails/maildir/bsd directory
                my $p = undef;
                my $o = undef;
                my $d = 0;
                my $g = undef;

                $p = Sisimai::Message->new('data' => $r);
                isa_ok $p,         'Sisimai::Message';
                isa_ok $p->ds,     'ARRAY';
                isa_ok $p->header, 'HASH';
                isa_ok $p->rfc822, 'HASH';

                ok length $p->from,    sprintf("[%s] %s->from = %s", $n, $M, $p->from);
                ok scalar @{ $p->ds }, sprintf("[%s] %s/ds entries = %d", $n, $M, scalar @{ $p->ds });

                for my $e ( @{ $p->ds } ) {
                    $d++;
                    $g = sprintf("%02d-%02d", $n, $d);

                    for my $ee ( qw|recipient agent| ) {
                        # Length of each variable > 0
                        ok length $e->{ $ee }, sprintf("[%s] %s->%s = %s", $g, $x, $ee, $e->{ $ee });
                    }

                    for my $ee ( qw|
                        date spec reason status command action alias rhost lhost 
                        diagnosis feedbacktype softbounce| ) {
                        # Each key should be exist
                        ok exists $e->{ $ee }, sprintf("[%s] %s->%s = %s", $g, $x, $ee, $e->{ $ee });
                    }

                    # Check the value of the following variables
                    if( $x eq 'X4' ) {
                        # X4 is qmail clone
                        like $e->{'agent'}, qr/(?:qmail|X4)/, sprintf("[%s] %s->agent = %s", $g, $x, $e->{'agent'});

                    } else {
                        # Other MTA modules
                        is $e->{'agent'}, 'MTA::'.$x, sprintf("[%s] %s->agent = %s", $g, $x, $e->{'agent'});
                    }

                    like   $e->{'recipient'}, qr/[0-9A-Za-z@-_.]+/, sprintf("[%s] %s->recipient = %s", $g, $x, $e->{'recipient'});
                    unlike $e->{'recipient'}, qr/[ ]/,              sprintf("[%s] %s->recipient = %s", $g, $x, $e->{'recipient'});
                    unlike $e->{'command'},   qr/[ ]/,              sprintf("[%s] %s->command = %s", $g, $x, $e->{'command'});

                    if( length $e->{'status'} ) {
                        # Check the value of "status"
                        like $e->{'status'}, qr/\A(?:[45][.]\d[.]\d+)\z/,
                            sprintf("[%s] %s->status = %s", $g, $x, $e->{'status'});
                    }

                    if( length $e->{'action'} ) {
                        # Check the value of "action"
                        like $e->{'action'}, qr/\A(?:fail.+|delayed|expired)\z/, 
                            sprintf("[%s] %s->action = %s", $g, $x, $e->{'action'});
                    }

                    for my $ee ( 'rhost', 'lhost' ) {
                        # Check rhost and lhost are valid hostname or not
                        next unless $e->{ $ee };
                        next if $x =~ m/\A(?:qmail|Exim|Exchange|X4)/;
                        next unless length $e->{ $ee };
                        like $e->{ $ee }, qr/\A(?:localhost|.+[.].+)\z/, sprintf("[%s] %s->%s = %s", $g, $x, $ee, $e->{ $ee });
                    }
                }


                $o = Sisimai::Data->make('data' => $p);
                isa_ok $o, 'ARRAY';
                ok scalar @$o, sprintf("%s/entry = %s", $M, scalar @$o);

                for my $e ( @$o ) {
                    # Check each accessor
                    isa_ok $e,            'Sisimai::Data';
                    isa_ok $e->timestamp, 'Sisimai::Time';
                    isa_ok $e->addresser, 'Sisimai::Address';
                    isa_ok $e->recipient, 'Sisimai::Address';

                    ok defined $e->replycode,      sprintf("[%s] %s->replycode = %s", $g, $x, $e->replycode);
                    ok defined $e->subject,        sprintf("[%s] %s->subject = ...", $g, $x);
                    ok defined $e->smtpcommand,    sprintf("[%s] %s->smtpcommand = %s", $g, $x, $e->smtpcommand);
                    ok defined $e->diagnosticcode, sprintf("[%s] %s->diagnosticcode = %s", $g, $x, $e->diagnosticcode);
                    ok defined $e->diagnostictype, sprintf("[%s] %s->diagnostictype = %s", $g, $x, $e->diagnostictype);
                    ok length  $e->deliverystatus, sprintf("[%s] %s->deliverystatus = %s", $g, $x, $e->deliverystatus);
                    ok length  $e->token,          sprintf("[%s] %s->token = %s", $g, $x, $e->token);
                    ok length  $e->smtpagent,      sprintf("[%s] %s->smtpagent = %s", $g, $x, $e->smtpagent);
                    ok length  $e->timezoneoffset, sprintf("[%s] %s->timezoneoffset = %s", $g, $x, $e->timezoneoffset);

                    is $e->addresser->host, $e->senderdomain, sprintf("[%s] %s->senderdomain = %s", $g, $x, $e->senderdomain);
                    is $e->recipient->host, $e->destination,  sprintf("[%s] %s->destination = %s", $g, $x, $e->destination);

                    cmp_ok $e->softbounce, '>=', -1, sprintf("[%s] %s->softbounce = %s", $g, $x, $e->softbounce);
                    cmp_ok $e->softbounce, '<=',  1, sprintf("[%s] %s->softbounce = %s", $g, $x, $e->softbounce);
                    like $e->softbounce, $MTAChildren->{ $x }->{ $n }->{'b'}, sprintf("[%s] %s->softbounce = %d", $g, $x, $e->softbounce);

                    like $e->replycode,      qr/\A(?:[45]\d\d|)\z/,          sprintf("[%s] %s->replycode = %s", $g, $x, $e->replycode);
                    like $e->timezoneoffset, qr/\A[-+]\d{4}\z/,              sprintf("[%s] %s->timezoneoffset = %s", $g, $x, $e->timezoneoffset);
                    like $e->deliverystatus, $MTAChildren->{$x}->{$n}->{'s'},sprintf("[%s] %s->deliverystatus = %s", $g, $x, $e->deliverystatus);
                    like $e->reason,         $MTAChildren->{$x}->{$n}->{'r'},sprintf("[%s] %s->reason = %s", $g, $x, $e->reason);
                    like $e->token,          qr/\A([0-9a-f]{40})\z/,         sprintf("[%s] %s->token = %s", $g, $x, $e->token);

                    unlike $e->deliverystatus,qr/[ \r]/, sprintf("[%s] %s->deliverystatus = %s", $g, $x, $e->deliverystatus);
                    unlike $e->diagnostictype,qr/[ \r]/, sprintf("[%s] %s->diagnostictype = %s", $g, $x, $e->diagnostictype);
                    unlike $e->smtpcommand,   qr/[ \r]/, sprintf("[%s] %s->smtpcommand = %s", $g, $x, $e->smtpcommand);

                    unlike $e->lhost,     qr/[ \r]/, sprintf("[%s] %s->lhost = %s", $g, $x, $e->lhost);
                    unlike $e->rhost,     qr/[ \r]/, sprintf("[%s] %s->rhost = %s", $g, $x, $e->rhost);
                    unlike $e->alias,     qr/[ \r]/, sprintf("[%s] %s->alias = %s", $g, $x, $e->alias);
                    unlike $e->listid,    qr/[ \r]/, sprintf("[%s] %s->listid = %s", $g, $x, $e->listid);
                    unlike $e->action,    qr/[ \r]/, sprintf("[%s] %s->action = %s", $g, $x, $e->action);
                    unlike $e->messageid, qr/[ \r]/, sprintf("[%s] %s->messageid = %s", $g, $x, $e->messageid);

                    unlike $e->addresser->user, qr/[ \r]/, sprintf("[%s] %s->addresser->user = %s", $g, $x, $e->addresser->user);
                    unlike $e->addresser->host, qr/[ \r]/, sprintf("[%s] %s->addresser->host = %s", $g, $x, $e->addresser->host);
                    unlike $e->addresser->verp, qr/[ \r]/, sprintf("[%s] %s->addresser->verp = %s", $g, $x, $e->addresser->verp);
                    unlike $e->addresser->alias,qr/[ \r]/, sprintf("[%s] %s->addresser->alias = %s", $g, $x, $e->addresser->alias);

                    unlike $e->recipient->user, qr/[ \r]/, sprintf("[%s] %s->recipient->user = %s", $g, $x, $e->recipient->user);
                    unlike $e->recipient->host, qr/[ \r]/, sprintf("[%s] %s->recipient->host = %s", $g, $x, $e->recipient->host);
                    unlike $e->recipient->verp, qr/[ \r]/, sprintf("[%s] %s->recipient->verp = %s", $g, $x, $e->recipient->verp);
                    unlike $e->recipient->alias,qr/[ \r]/, sprintf("[%s] %s->recipient->alias = %s", $g, $x, $e->recipient->alias);
                }
                $c++;
            }
        }
        ok $c, $M.'/the number of emails = '.$c;
    }
}

done_testing;
