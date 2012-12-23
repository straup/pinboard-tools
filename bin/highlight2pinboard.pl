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

B<-c> is for "config"

The path to a config file containing your pinboard.in credentials.

=item *

B<-p> is for "public"

Make the highlight public on pinboard.in. Default is false.

=item *

B<-n> is for "note"

Post the highlight to pinboard.in as a "note" (rather than a bookmark). Default is false.

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

=item

L<WWW::Mechanize> - this is only required if you need to post highlights as
a "note"

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

    getopts('c:pn', \%opts);

    if (! -f $opts{'c'}){
	warn "Not a valid config file";
	return 0;
    }

    my $public = ($opts{'p'}) ? 1 : 0;
    my $as_note = ($opts{'n'}) ? 1 : 0;

    if ($as_note){
	    use WWW::Mechanize
    }
	
    my $cfg = Config::Simple->new($opts{'c'});
    my $del = Net::Delicious->new($cfg);

    while (<STDIN>){
	$txt .= $_;
    }

    if (my $note = parse_email($txt)){

	if ($as_note){
	    post_as_note($cfg, $note, $public);
	}

	else {
	    post_as_link($del, $note, $public);
	}
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

sub post_as_link {
    my $del = shift;
    my $note = shift;
    my $public = shift;

    my $body = $note->{'body'};
    my $md5_body = md5_hex($body);
    my $md5_url = md5_hex($note->{'url'});

    my $url = $note->{'url'} . "#" . $md5_body;
    my $title = $note->{'title'} . " #" . $md5_body;

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

# See also: https://gist.github.com/3968495

sub post_as_note {
    my $cfg = shift;
    my $note = shift;
    my $public = shift;

    my $username = $cfg->param('delicious.user');
    my $password = $cfg->param('delicious.pswd');

    my $md5_url = md5_hex($note->{'url'});

    my $title = $note->{'title'};
    my $tags = join(",", ("highlights", $note->{'tags'}, "url:" . $md5_url));
    my $body = join("\n\n", ($note->{'body'}, $note->{'url'}));

    # Go!

    my $action = ($public) ? 'save_public' : 'save_private';
    my $button = ($public) ? 'save public' : 'save private';

    my $m = WWW::Mechanize->new();
    $m->get("https://pinboard.in/");

    $m->field('username', $username);
    $m->field('password', $password);
    $m->submit();

    # There's actually not much in the way of error checking
    # the login but at least we can see if the server freaks
    # out

    if ($m->status != 200){
	warn "failed to log in: " . $m->message;
	return 0;
    }

    # Now add the note - see also:
    # http://search.cpan.org/~jesse/WWW-Mechanize/lib/WWW/Mechanize/FAQ.pod#I_submitted_a_form,_but_the_server_ignored_everything!_I_got_an_empty_form_back!

    $m->get("https://pinboard.in/note/add/");

    $m->field('title', $title);
    $m->field('tags', $tags);
    $m->field('note', $body);
    $m->field('action', $action);
    $m->click_button('value', $button);

    if ($m->status != 200){
	warn "failed to post note: " . $m->message;
	return 0;
    }

    return 1;
}
