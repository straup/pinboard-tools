#!/usr/bin/env perl

=head1 NAME

kindle-highlights2pinboard.pl

=head1 SYNOPSIS

 $> ./kindle-highlights2pinboard.pl -c pinboard.cfg -h /path/to/your-kindle/My\ Clippings.txt

=head1 DESCRIPTION

kindle-highlights2pinboard is a simple Perl script that parses a Kindle 'My
Clippings.txt' text file containing things you've highlighted posts them to
your pinboard.in account. 

An example highlight-as-bookmark might look like this:

 Embassytown (China Mieville) # Highlight on Page 50 | Loc. 819 | Added on Wednesday, September 21, 2011, 02:06 PM 
 https://kindle.amazon.com/your_highlights#c10eab6dd218094b4d431aed2f9f7e0d-07f6087fc6d3f8b472db0b0faba7a8b5

 People get lost in the overlapping sets of knownspace.

 highlights  kindle  dt:year=2011  dt:month=09  dt:day=21
 md5:book=c10eab6dd218094b4d431aed2f9f7e0d
 md5:author=cc5441eadbbb66059bb34c89bfed9fcb  

Specifically:

=over 4

=item *

The title and author(s) of the book as well as the time location of the
highlight are stored as the title of the bookmark.

=item *

The URL is the Kindle highlights website with an MD5 hash of the title (and
author) of the book and an MD5 hash of the highlight location, separated by a
dash. This is not ideal but Pinboard does not support the 'kindle://'
protocol scheme and there's no good and simple way to look up an ISBN so that we
could link to the Open Library or something.

=item *

The text of the highlight itself.

=item *

A number of tags: 'highlights'; 'kindle'; machine tags for the year, month and
day the highlight was recorded; machine tags for both the MD5 hash of the book's
title and author(s)

=back

=head1 COMMAND LINE OPTIONS

=over 4

=item *

B<-c> is for "config"

The path to a config file containing your pinboard.in credentials.

=item *

B<-h> is for "highlights"

The path to your 'My Clippings.txt' file.

=item *

B<-p> is for "public"

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

L<Date::Parse>

=item

L<Date::Format>

=item

L<Config::Simple>

=back

=head1 LICENSE

Copyright (c) 2012, Aaron Straup Cope. All Rights Reserved.

This is free software, you may use it and distribute it under the same terms as Perl itself.

=cut

use strict;

use Getopt::Std;
use Net::Delicious;
use Config::Simple;
use Date::Parse qw(str2time);
use Date::Format qw(time2str);
use Digest::MD5 qw(md5_hex);

# for when we look up ISBN numbers
# use URI;
# use LWP::UserAgent;
# use HTTP::Request;
# use Memoize;
# memoize('lookup_isbn');

{
    &main();
    exit;
}

sub main {

    # Yes, that's right – it's necessary or LWP::UA
    # will freak out and die

    $ENV{'PERL_LWP_SSL_VERIFY_HOSTNAME'} = 0;

    my %opts = ();

    getopts('c:h:p', \%opts);

    if (! -f $opts{'c'}){
	warn "Not a valid config file";
	return 0;
    }

    my $public = ($opts{'p'}) ? 1 : 0;
	
    my $cfg = Config::Simple->new($opts{'c'});
    my $del = Net::Delicious->new($cfg);

    my $highlights = parse_highlights($opts{'h'});

    foreach my $h (@$highlights){
	post_as_link($del, $h, $public);
    }

    return 1;
}

sub parse_highlights {
    my $path = shift;

    my @highlights = ();

    local $/ = "\r\n==========\r\n";

    open FH, $path;

    while (<FH>){

	my $ln = $_;
	$ln =~ s/^\xef\xbb\xbf//;

	my @parts = split(/\r\n/, $ln);

	my $book = shift(@parts);
	my $location = shift(@parts);
	my $cruft = pop(@parts);

	$book =~ /^(.*)\s+\((.*)\)$/;
	my $title = $1;
	my $author = $2;

	if (! $title){
	    $title = $book;
	}

	my $txt = join("\n\n", @parts);
	$txt =~ s/^\s+//;
	$txt =~ s/\s+$//;

	$location =~ s/^- //;

	my @loc = split(/\s+\|\s+/, $location);
	my $page;
	my $pos;
	my $date;

	if (scalar(@loc) == 2){

	    $loc[0] =~ /loc\. (.*)/i;
	    $pos = $1;

	    $loc[1] =~ /added on (.*)/i;
	    $date = $1;
	}

	else {

	    $loc[0] =~ /page (\d+)/i;
	    $page = $1;

	    $loc[1] =~ /loc\. (.*)/i;
	    $pos = $1;

	    $loc[2] =~ /added on (.*)/i;
	    $date = $1;
	}

	my $ts = str2time($date);

	my %highlight = (
	    'book' => $book,
	    'title' => $title,
	    'author' => $author,
	    'location' => $location,
	    'page' => $page,
	    'position' => $pos,
	    'date' => $date,
	    'timestamp' => $ts,
	    'text' => $txt
	    );

	# Oh Amazon, would that you include ISBN/ASIN numbers in the
	# highlights files... (20121224/straup)

	push @highlights, \%highlight;
    }

    return \@highlights;
}

sub post_as_link {
    my $del = shift;
    my $highlight = shift;
    my $public = shift;

    my $md5_title = md5_hex($highlight->{'title'});
    my $md5_author = md5_hex($highlight->{'author'});

    my $md5_book = md5_hex($highlight->{'book'});
    my $md5_location = md5_hex($highlight->{'location'});

    my @tags = (
	"highlights",
	"kindle",
	"dt:year=" . time2str("%Y", $highlight->{'timestamp'}),
	"dt:month=" . time2str("%m", $highlight->{'timestamp'}),
	"dt:day=" . time2str("%d", $highlight->{'timestamp'}),
	"md5:book=" . $md5_book,
	"md5:author=" . $md5_author,
	);

    # these ones all seem kind of pointless, really
    # (20121224/straup)

    if (0){
	push @tags, "kindle:location=" . $highlight->{'position'};
	push @tags, "dt:timestamp=" . $highlight->{'timestamp'};

	if ($highlight->{'page'}){
	    push @tags, "kindle:page=" . $highlight->{'page'};
	}
    }
    
    my $tags = join(",", @tags);

    # Oh Amazon, would that you let me actually link to things
    # this way and/or for pinboard.in to support kindle:// URIs
    # (20121224/straup)

    # See also: kindle://book?action=open&asin=B005CRQ3MA&location=62

    my $url = "https://kindle.amazon.com/your_highlights#" . join("-", ($md5_book, $md5_location));

    my %post = (
	'url' => $url,
	'description' => join(" # ", ($highlight->{'book'}, $highlight->{'location'})),
	'extended' => $highlight->{'text'},
	'tags' => $tags,
	'shared' => $public,
	);

    my $rsp = $del->add_post(\%post);
    return $rsp;
}

# this doesn't really work, dunno why... (20121224/straup)
# https://isbndb.com/docs/api/51-books.html

sub lookup_isbn {
    my $book = shift;
    my $key = shift;

    my %args = (
	'access_key' => $key, 
	'index1' => 'full',
	'value1' => $book
	);

    my $uri = URI->new("https://isbndb.com/api/books.xml");
    $uri->query_form(\%args);

    my $url = $uri->canonical();

    my $ua = LWP::UserAgent->new();
    my $req = HTTP::Request->new(GET => $url);

    my $rsp = $ua->request($req);
    # print $rsp->as_string();
}
