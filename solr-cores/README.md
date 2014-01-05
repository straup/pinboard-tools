solr-cores
==

Still experimental code and config files for storing stuff from pinboard.in
(bookmarks, notes and Twitter data exported as JSON files) in Solr. If you are
already familiar with Solr you shouldn't have too much trouble getting things
set up.

It doesn't really do anything yet and I'm not really sure what it _will_ do but
there are tools for importing the JSON exports from pinboard. (20121223/straup)

pinboard
--

### pinboard2solr.py

Import your Pinboard bookmarks in to Solr (note the optional "purge-ing" of
existing bookmarks before we do):

	./bin/pinboard2solr.py -p ./pinboard.json --purge

### dump-highlights.py

Generate an HTML dump of a subset of your bookmarks suitable for generating a
PDF book using [wkpdf](http://plessl.github.com/wkpdf/):

	$> ./bin/dump-highlights.py -y 2012 -f '-machinetags:dt8cyear8e2011' \
	   -t 'dog-eared 2012' | wkpdf -o dog-eared-2012.pdf -p custom:432x648 \
	   -m 54 36 72 36

twitter
--

### twitter2solr.py

Import a Twitter account in to Solr:

	$> ./bin/twitter2solr.py -t ~/Desktop/pinboard-thisisaaronland.json

### mk-twitter-book.php

Make a shiny PDF book ([like this](http://www.flickr.com/photos/straup/8307297720/)) of all your Twitter messages for a
year:

	$> php -q ./bin/mk-twitter-book/mk-twitter-book.php \
	   -o thisisaaronland-2012.pdf -u thisisaaronland -y 2012

You can also optionally exclude reply-to messages and retweets by passing the
`-r 1` and `-t 1` flags respectively. _Note the explicit boolean `1`. This is
currently still required but not considered a feature._

Known-knowns
--

### machine tags

It's currently not possible to search for links in the `pinboard` core using
machine tags because some of the characters used to encode machine tags are
reserved in Solr/Lucene land. This will worked out eventually.

### timezones

Always with the timezones...

Dependencies
--

Most of the things are here are pretty self-contained but you will need to make
sure that you have the following dependencies installed:

* [Apache Solr 4.0.0](http://lucene.apache.org/solr/) or higher

* [pysolr](http://pypi.python.org/pypi/pysolr)

See also
--

* [the pinboard.in export bookmarks/tweets page](https://pinboard.in/export/)
