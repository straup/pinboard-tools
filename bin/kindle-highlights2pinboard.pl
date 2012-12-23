#!/usr/bin/env perl

# THIS DOESN'T WORK YET (20121223/straup)

use Net::Delicious;
use Config::Simple;
use Data::Dumper;

{
    &main();
    exit;
}

sub main {

    my $path = $ARGV[0];
    parse_highlights($path);
}

sub parse_highlights {
    my $path = shift;

    my @highlights = ();

    local $/ = "==========";

    open FH, $path;

    while (<FH>){

	my $ln = $_;
	my @parts = split(/\r\n/, $ln);

	my $book = shift(@parts);
	my $location = shift(@parts);
	my $cruft = pop(@parts);

	my $txt = join("\n\n", @parts);
	$txt =~ s/^\s+//;
	$txt =~ s/\s+$//;

	my @loc = split(/\s+\|\s+/, $location);

	$loc[0] =~ /page (\d+)/i;
	my $page = $1;

	$loc[1] =~ /loc\. (.*)/i;
	my $pos = $1;

	$loc[2] =~ /added on (.*)/i;
	my $date = $1;

	my %highlight = (
	    'book' => $book,
	    'location' => $loc,
	    'page' => $page,
	    'position' => $pos,
	    'date' => $date,
	    'text' => $txt
	    );

	push @highlights, \%highlight;

	print Dumper(\%highlight);
    }
}
