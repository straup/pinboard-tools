#!/usr/bin/env perl

=head1 NAME

highlight2pinboard.pl

=head1 SYNOPSIS

 $> ./highlight2pinboard.pl -c pinboard.cfg < some-message.eml

=head1 DESCRIPTION

highlight2pinboard is a simple Perl script that parses an email containing a
highlight sent from Instapaper and posts it your pinboard.in account.

(There's no reason that the script couldn't accept email from other services but
at the moment it doesn't know how to. Patches are welcome and encouraged.)

URLs are appended with an MD5 hash of the text you've highlighted so that they
will remain unique in the pinboard database. In addition to being tagged with
'highlights' and 'from:instapaper' every link is tagged with 'url:' + the MD5
hash of the raw URL so you can easily find highlights from the same document.

It can be run from the command line or (more likely) as an upload-by-email style
handler or callback that you'll need to configure yourself.

=head1 COMMAND LINE OPTIONS

=over 4

=item *

B<--config> -c

The path to a config file containing your pinboard.in credentials.

=item *

B<--public> -p

Make the highlight public on pinboard.in. Default is false.

=back

=head1 CONFIG FILE

Config variables are defined in a plain vanilla '.ini' file. Because this script
uses Net::Delicious (pinboard mirrors the delicious API) you'll need to add
things inside a 'delicious' block. For example:

 [delicious]
 user=YOUR_PINBOARD_USERNAME
 pswd=YOUR_PINBOARD_PASSWORD
 endpoint=https://api.pinboard.in/v1/
 debug=0

Note how we're over-riding the default (delicious) endpoint.

=head1 DEPENDENCIES

=over 4

=item

L<Net::Delicious>

=item

L<Email::MIME>

=item

L<Config::Simple>

=back

=head1 LICENSE

Copyright (c) 2012, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

use strict;

use Getopt::Std;
use Config::Simple;

use Email::MIME;
use Net::Delicious;
use Digest::MD5 qw (md5_hex);

{
    &main();
    exit;
}

sub main {

    # Yes, that's right – it's necessary or LWP::UA
    # will freak out and die

    $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

    my $txt = '';
    my %opts = ();

    getopts('c:p', \%opts);

    if (! -f $opts{'c'}){
	warn "Not a valid config file";
	return 0;
    }

    my $cfg = Config::Simple->new($opts{'c'});
    my $del = Net::Delicious->new($cfg);

    while (<STDIN>){
	$txt .= $_;
    }

    if (my $note = parse_email($txt)){

	my $public = ($opts{'p'}) ? 1 : 0;
	post_note($del, $note, $public);
    }
    
    return 1;
}

sub parse_email {
    my $txt = shift;

    my $email = Email::MIME->new($txt);
    my @parts = $email->parts;

    my $note = undef;

    foreach my $p (@parts){

	my $type = $p->content_type;

	if ($type !~ m!^text/plain!){
	    next;
	}

	my $body = $p->body;
	$body =~ s/\r/\n/g;

	if ($body =~ /via Instapaper/mi){
	    $note = parse_instapaper($body);
	}

	last;
    }

    if (! $note){
	warn "Can't find note";
	return undef;
    }

    return $note;
}

sub parse_instapaper {
    my $txt = shift;

    my @parts = split("\n", $txt);

    my %note = (
	'tags' => 'from:instapaper',
	);

    my @body = ();

    foreach my $ln (@parts){

	if (! $ln){
	    next;
	}

	if (! $note{'title'}){
	    $note{'title'} = $ln;
	    next;
	}

	if (! $note{'url'}){
	    $note{'url'} = $ln;
	    next;
	}

	if ($ln =~ /via Instapaper/i){
	    $note{'body'} = join("\n\n", @body);
	    last;
	}

	push @body, $ln;
    }

    return \%note;
}

sub post_note {
    my $del = shift;
    my $note = shift;
    my $public = shift;

    my $body = $note->{'body'};
    my $md5_body = md5_hex($body);
    my $md5_url = md5_hex($note->{'url'});

    my $url = $note->{'url'} . "#" . $md5_body;
    my $title = $note->{'title'} . "(" . $md5_body . ")";

    my $tags = join(",", ("highlights", $note->{'tags'}, "url:" . $md5_url));

    my %post = (
	'url' => $url,
	'description' => $title,
	'extended' => $body,
	'tags' => $tags,
	'shared' => $public,
	);

    my $rsp = $del->add_post(\%post);
    return $rsp;
}
