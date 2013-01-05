#!/usr/bin/env perl

use strict;
use utf8;

use Getopt::Std;
use Config::Simple;

use Net::Delicious;

use FileHandle;
use JSON::Any;

{
    &main();
    exit;
}

sub main {

    warn "This doesn't work very well and should probably just stop using Net::Delicious - enable and use as at your own risk";
    exit;

    # Yes, that's right – it's necessary or LWP::UA
    # will freak out and die

    $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

    my %opts = ();

    getopts('c:o:', \%opts);

    if (! -f $opts{'c'}){
	warn "Not a valid config file";
	return 0;
    }
	
    my $cfg = Config::Simple->new($opts{'c'});
    my $del = Net::Delicious->new($cfg);

    # An old delicious-ism

    my $lock = $del->_path_update();

    if (-f $lock){
	unlink($lock);
    }

    my $posts = $del->all_posts();

    my $fh = FileHandle->new();
    $fh->open($opts{'o'}, 'w');

    # binmode $fh, ':utf8';

    my $json = JSON::Any->new();

    while (my $post = $posts->next()){

	my $row = $post->as_hashref();

	# Also, due to old Net::Delicious-isms...

	$row->{'toread'} = "";
	$row->{'hash'} = "";
	$row->{'meta'} = "";

	delete $row->{'parent'};

	$fh->print($json->encode($row));
    }


    $fh->close();

    return;
}
