#!/usr/bin/env perl

# A simple tool to fetch bookmarks and optional twitter account
# data from https://pinboard.in/export/

# For example:
# perl ./bin/export.pl -c pinboard.cfg -t twitterhandle -o ~/pinboard

use strict;
use Getopt::Std;
use Config::Simple;
use WWW::Mechanize;
use FileHandle;
use File::Spec;

{
    &main();
    exit();
}

sub main {

    # Yes, that's right – it's necessary or LWP::UA
    # will freak out and die

    $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

    my %opts = ();
    getopts('c:t:o:', \%opts);

    if (! -f $opts{'c'}){
	warn "Not a valid config file";
	return 0;
    }

    if (! -d $opts{'o'}){
	warn "Not a valid output directory";
	return 0;
    }
	
    my $cfg = Config::Simple->new($opts{'c'});

    my $username = $cfg->param('pinboard.user');
    my $password = $cfg->param('pinboard.pswd');

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

    my @files = ();

    push @files, [
	"https://pinboard.in/export/format:json/",
	File::Spec->catfile($opts{'o'}, "pinboard-bookmarks.json")
	];
    
    # TO DO: untaint $opts{'t'} (20130601/straup)

    if ($opts{'t'}){

	foreach my $acct (split(/,/, $opts{'t'})){

	    push @files, [
		"https://pinboard.in/export/tweets/$acct/format:json/",
		File::Spec->catfile($opts{'o'}, "twitter-$acct.json")
	    ];

	}

    }

    foreach my $f (@files){

	my $remote = $f->[0];
	my $local = $f->[1];

	print "fetch $remote\n";

	my $rsp = $m->get($remote);
	my $status = $m->status;

	if ($status != 200){
	    print "failed to fetch $remote ($status)\n";
	    next;
	}

	my $fh = FileHandle->new();
	binmode $fh, ':utf8';

	$fh->open($local, "w");

	chmod oct("0600"), $local;

	$fh->print($rsp->content());
	$fh->close();

	print "wrote $local\n";
    }

    return 1;
}
