#!/usr/bin/env perl

use Getopt::Std;
use Net::Delicious;
use Config::Simple;
use Data::Dumper;
use Date::Parse qw(str2time);
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
	exit;
    }
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

	# kindle://book?action=open&asin=B005CRQ3MA&location=62

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

	push @highlights, \%highlight;
    }

    return \@highlights;
}

sub post_as_link {
    my $del = shift;
    my $highlight = shift;
    my $public = shift;

    print Dumper($highlight);

    my $md5_title = md5_hex($highlight->{'title'});
    my $md5_author = md5_hex($highlight->{'author'});

    my $md5_book = md5_hex($highlight->{'book'});
    my $md5_location = md5_hex($highlight->{'location'});

    my @tags = (
	"highlights",
	"unix:timestamp=" . $highlight->{'timestamp'},
	"md5:book=" . $md5_book,
	"md5:author=" . $md5_author,
	"kindle:location=" . $highlight->{'position'},
	);

    if ($highlight->{'page'}){
	push @tags, "kindle:page=" . $highlight->{'page'};
    }

    my $tags = join(",", @tags);

    my $url = "x-urn:kindle:highlight#" . join("-", ($md5_book, $md5_location));

    my %post = (
	'url' => $url,
	'description' => join(" # ", ($highlight->{'book'}, $highlight->{'location'})),
	'extended' => $highlight->{'text'},
	'tags' => $tags,
	'shared' => $public,
	);

    print Dumper(\%post);
    exit;

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
