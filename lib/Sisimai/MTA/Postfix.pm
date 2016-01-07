package Sisimai::MTA::Postfix;
use parent 'Sisimai::MTA';
use feature ':5.10';
use strict;
use warnings;

# Postfix manual - bounce(5) - http://www.postfix.org/bounce.5.html
my $Re0 = {
    'from'    => qr/ [(]Mail Delivery System[)]\z/,
    'subject' => qr/\AUndelivered Mail Returned to Sender\z/,
};
my $Re1 = {
    'begin' => qr{\A(?>
         [ ]+The[ ](?:
             Postfix[ ](?:
                 program\z              # The Postfix program
                |on[ ].+[ ]program\z    # The Postfix on <os name> program
                )
            |\w+[ ]Postfix[ ]program\z  # The <name> Postfix program
            |mail[ \t]system\z             # The mail system
            |\w+[ \t]program\z             # The <custmized-name> program
            )
        |This[ ]is[ ]the[ ](?:
             Postfix[ ]program          # This is the Postfix program
            |\w+[ ]Postfix[ ]program    # This is the <name> Postfix program
            |\w+[ ]program              # This is the <customized-name> Postfix program
            |mail[ ]system[ ]at[ ]host  # This is the mail system at host <hostname>.
            )
        )
    }x,
    'rfc822'  => qr!\AContent-Type:[ \t]*(?:message/rfc822|text/rfc822-headers)\z!x,
    'endof'   => qr/\A__END_OF_EMAIL_MESSAGE__\z/,
};

my $Indicators = __PACKAGE__->INDICATORS;
my $LongFields = Sisimai::RFC5322->LONGFIELDS;
my $RFC822Head = Sisimai::RFC5322->HEADERFIELDS;

sub description { 'Postfix' }
sub smtpagent   { 'Postfix' }
sub pattern     { return $Re0 }

sub scan {
    # Parse bounce messages from Postfix
    # @param         [Hash] mhead       Message header of a bounce email
    # @options mhead [String] from      From header
    # @options mhead [String] date      Date header
    # @options mhead [String] subject   Subject header
    # @options mhead [Array]  received  Received headers
    # @options mhead [String] others    Other required headers
    # @param         [String] mbody     Message body of a bounce email
    # @return        [Hash, Undef]      Bounce data list and message/rfc822 part
    #                                   or Undef if it failed to parse or the
    #                                   arguments are missing
    # @since v4.0.0
    my $class = shift;
    my $mhead = shift // return undef;
    my $mbody = shift // return undef;

    return undef unless $mhead->{'subject'} =~ $Re0->{'subject'};

    my $dscontents = []; push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
    my @hasdivided = split( "\n", $$mbody );
    my $rfc822next = { 'from' => 0, 'to' => 0, 'subject' => 0 };
    my $rfc822part = '';    # (String) message/rfc822-headers part
    my $previousfn = '';    # (String) Previous field name
    my $readcursor = 0;     # (Integer) Points the current cursor position
    my $recipients = 0;     # (Integer) The number of 'Final-Recipient' header
    my @commandset = ();    # (Array) ``in reply to * command'' list
    my $connvalues = 0;     # (Integer) Flag, 1 if all the value of $connheader have been set
    my $connheader = {
        'date'    => '',    # The value of Arrival-Date header
        'lhost'   => '',    # The value of Received-From-MTA header
    };
    my $anotherset = {};    # Another error information

    my $v = undef;
    my $p = '';

    for my $e ( @hasdivided ) {
        # Read each line between $Re1->{'begin'} and $Re1->{'rfc822'}.
        unless( $readcursor ) {
            # Beginning of the bounce message or delivery status part
            if( $e =~ $Re1->{'begin'} ) {
                $readcursor |= $Indicators->{'deliverystatus'};
                next;
            }
        }

        unless( $readcursor & $Indicators->{'message-rfc822'} ) {
            # Beginning of the original message part
            if( $e =~ $Re1->{'rfc822'} ) {
                $readcursor |= $Indicators->{'message-rfc822'};
                next;
            }
        }

        if( $readcursor & $Indicators->{'message-rfc822'} ) {
            # After "message/rfc822"
            if( $e =~ m/\A([-0-9A-Za-z]+?)[:][ ]*.*\z/ ) {
                # Get required headers only
                my $lhs = lc $1;
                $previousfn = '';
                next unless exists $RFC822Head->{ $lhs };

                $previousfn  = $lhs;
                $rfc822part .= $e."\n";

            } elsif( $e =~ m/\A[ \t]+/ ) {
                # Continued line from the previous line
                next if $rfc822next->{ $previousfn };
                $rfc822part .= $e."\n" if exists $LongFields->{ $previousfn };

            } else {
                # Check the end of headers in rfc822 part
                next unless exists $LongFields->{ $previousfn };
                next if length $e;
                $rfc822next->{ $previousfn } = 1;
            }

        } else {
            # Before "message/rfc822"
            next unless $readcursor & $Indicators->{'deliverystatus'};
            next unless length $e;

            if( $connvalues == scalar( keys %$connheader ) ) {
                # Final-Recipient: RFC822; userunknown@example.jp
                # X-Actual-Recipient: RFC822; kijitora@example.co.jp
                # Action: failed
                # Status: 5.1.1
                # Remote-MTA: DNS; mx.example.jp
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
                $v = $dscontents->[ -1 ];

                if( $e =~ m/\A[Ff]inal-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*(.+)\z/ ) {
                    # Final-Recipient: RFC822; userunknown@example.jp
                    if( length $v->{'recipient'} ) {
                        # There are multiple recipient addresses in the message body.
                        push @$dscontents, __PACKAGE__->DELIVERYSTATUS;
                        $v = $dscontents->[ -1 ];
                    }
                    $v->{'recipient'} = $1;
                    $recipients++;

                } elsif( $e =~ m/\A[Xx]-[Aa]ctual-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/ ||
                         $e =~ m/\A[Oo]riginal-[Rr]ecipient:[ ]*(?:RFC|rfc)822;[ ]*([^ ]+)\z/ ) {
                    # X-Actual-Recipient: RFC822; kijitora@example.co.jp
                    # Original-Recipient: rfc822;kijitora@example.co.jp
                    $v->{'alias'} = $1;

                } elsif( $e =~ m/\A[Aa]ction:[ ]*(.+)\z/ ) {
                    # Action: failed
                    $v->{'action'} = lc $1;

                } elsif( $e =~ m/\A[Ss]tatus:[ ]*(\d[.]\d+[.]\d+)/ ) {
                    # Status: 5.1.1
                    # Status:5.2.0
                    # Status: 5.1.0 (permanent failure)
                    $v->{'status'} = $1;

                } elsif( $e =~ m/\A[Rr]emote-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/ ) {
                    # Remote-MTA: DNS; mx.example.jp
                    $v->{'rhost'} = lc $1;

                } elsif( $e =~ m/\A[Ll]ast-[Aa]ttempt-[Dd]ate:[ ]*(.+)\z/ ) {
                    # Last-Attempt-Date: Fri, 14 Feb 2014 12:30:08 -0500
                    #
                    # src/bounce/bounce_notify_util.c:
                    #   681  #if 0
                    #   682      if (dsn->time > 0)
                    #   683          post_mail_fprintf(bounce, "Last-Attempt-Date: %s",
                    #   684                            mail_date(dsn->time));
                    #   685  #endif
                    $v->{'date'} = $1;

                } else {
                    if( $e =~ m/\A[Dd]iagnostic-[Cc]ode:[ ]*(.+?);[ ]*(.+)\z/ ) {
                        # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                        $v->{'spec'} = uc $1;
                        $v->{'spec'} = 'SMTP' if $v->{'spec'} eq 'X-POSTFIX';
                        $v->{'diagnosis'} = $2;

                    } elsif( $p =~ m/\A[Dd]iagnostic-[Cc]ode:[ ]*/ && $e =~ m/\A[ \t]+(.+)\z/ ) {
                        # Continued line of the value of Diagnostic-Code header
                        $v->{'diagnosis'} .= ' '.$1;
                        $e = 'Diagnostic-Code: '.$e;
                    }
                }
            } else {
                # If you do so, please include this problem report. You can
                # delete your own text from the attached returned message.
                #
                #           The mail system
                #
                # <userunknown@example.co.jp>: host mx.example.co.jp[192.0.2.153] said: 550
                # 5.1.1 <userunknown@example.co.jp>... User Unknown (in reply to RCPT TO
                # command)
                if( $e =~ m/[ \t][(]in reply to ([A-Z]{4}).*/ ) {
                    # 5.1.1 <userunknown@example.co.jp>... User Unknown (in reply to RCPT TO
                    push @commandset, $1;

                } elsif( $e =~ m/([A-Z]{4})[ \t]*.*command[)]\z/ ) {
                    # to MAIL command)
                    push @commandset, $1;

                } else {

                    if( $e =~ m/\A[Rr]eporting-MTA:[ ]*(?:DNS|dns);[ ]*(.+)\z/ ) {
                        # Reporting-MTA: dns; mx.example.jp
                        next if $connheader->{'lhost'};
                        $connheader->{'lhost'} = $1;
                        $connvalues++;

                    } elsif( $e =~ m/\A[Aa]rrival-[Dd]ate:[ ]*(.+)\z/ ) {
                        # Arrival-Date: Wed, 29 Apr 2009 16:03:18 +0900
                        next if $connheader->{'date'};
                        $connheader->{'date'} = $1;
                        $connvalues++;

                    } elsif( $e =~ m/\A(X-Postfix-Sender):[ ]*rfc822;[ ]*(.+)\z/ ) {
                        # X-Postfix-Sender: rfc822; shironeko@example.org
                        $rfc822part .= sprintf( "%s: %s\n", $1, $2 );

                    } else {
                        # Alternative error message and recipient
                        if( $e =~ m/\A[<]([^ ]+[@][^ ]+)[>] [(]expanded from [<](.+)[>][)]:[ \t]*(.+)\z/ ) {
                            # <r@example.ne.jp> (expanded from <kijitora@example.org>): user ...
                            $anotherset->{'recipient'} = $1;
                            $anotherset->{'alias'}     = $2;
                            $anotherset->{'diagnosis'} = $3;

                        } elsif( $e =~ m/\A[<]([^ ]+[@][^ ]+)[>]:(.*)\z/ ) {
                            # <kijitora@exmaple.jp>: ...
                            $anotherset->{'recipient'} = $1;
                            $anotherset->{'diagnosis'} = $2;

                        } else {
                            # Get error message continued from the previous line
                            next unless $anotherset->{'diagnosis'};
                            if( $e =~ m/\A[ \t]{4}(.+)\z/ ) {
                                #    host mx.example.jp said:...
                                $anotherset->{'diagnosis'} .= ' '.$e;
                            }
                        }
                    }
                }
            }
        } # End of if: rfc822

    } continue {
        # Save the current line for the next loop
        $p = $e;
    }

    unless( $recipients ) {
        # Fallback: set recipient address from error message
        if( defined $anotherset->{'recipient'} && length $anotherset->{'recipient'} ) {
            # Set recipient address
            $dscontents->[-1]->{'recipient'} = $anotherset->{'recipient'};
            $recipients++;
        }
    }
    return undef unless $recipients;

    require Sisimai::String;
    require Sisimai::SMTP;
    require Sisimai::SMTP::Status;

    for my $e ( @$dscontents ) {
        # Set default values if each value is empty.
        map { $e->{ $_ } ||= $connheader->{ $_ } || '' } keys %$connheader;

        $e->{'agent'}   = __PACKAGE__->smtpagent;
        $e->{'command'} = shift @commandset || '';

        if( exists $anotherset->{'diagnosis'} && length $anotherset->{'diagnosis'} ) {
            # Copy alternative error message
            $e->{'diagnosis'} ||= $anotherset->{'diagnosis'};
            if( $e->{'diagnosis'} =~ m/\A\d+\z/ ) {
                # Override the value of diagnostic code message
                $e->{'diagnosis'} = $anotherset->{'diagnosis'};
            }
        }
        $e->{'diagnosis'} = Sisimai::String->sweep( $e->{'diagnosis'} );
        $e->{'spec'} ||= 'SMTP' if $e->{'diagnosis'} =~ m/host .+ said:/;

        if( scalar @{ $mhead->{'received'} } ) {
            # Get localhost and remote host name from Received header.
            my $r0 = $mhead->{'received'};
            $e->{'lhost'} ||= shift @{ Sisimai::RFC5322->received( $r0->[0] ) };
            $e->{'rhost'} ||= pop @{ Sisimai::RFC5322->received( $r0->[-1] ) };
        }

        if( length( $e->{'status'} ) == 0 || $e->{'status'} =~ m/\A\d[.]0[.]0\z/ ) {
            # There is no value of Status header or the value is 5.0.0, 4.0.0
            my $r = Sisimai::SMTP::Status->find( $e->{'diagnosis'} );
            $e->{'status'} = $r if length $r;
        }
    }
    return { 'ds' => $dscontents, 'rfc822' => $rfc822part };
}

1;
__END__

=encoding utf-8

=head1 NAME

Sisimai::MTA::Postfix - bounce mail parser class for C<Postfix>.

=head1 SYNOPSIS

    use Sisimai::MTA::Postfix;

=head1 DESCRIPTION

Sisimai::MTA::Postfix parses a bounce email which created by C<Postfix>. Methods 
in the module are called from only Sisimai::Message.

=head1 CLASS METHODS

=head2 C<B<description()>>

C<description()> returns description string of this module.

    print Sisimai::MTA::Postfix->description;

=head2 C<B<smtpagent()>>

C<smtpagent()> returns MTA name.

    print Sisimai::MTA::Postfix->smtpagent;

=head2 C<B<scan( I<header data>, I<reference to body string>)>>

C<scan()> method parses a bounced email and return results as a array reference.
See Sisimai::Message for more details.

=head1 AUTHOR

azumakuniyuki

=head1 COPYRIGHT

Copyright (C) 2014-2016 azumakuniyuki, All rights reserved.

=head1 LICENSE

This software is distributed under The BSD 2-Clause License.

=cut

