solr-cores
==

Still experimental code and config files for storing stuff from pinboard.in
(bookmarks, notes and Twitter data exported as JSON files) in Solr. If you are
already familiar with Solr you shouldn't have too much trouble getting things
set up.

It doesn't really do anything yet and I'm not really sure what it _will_ do but
there are tools for importing the JSON exports from pinboard. (20121223/straup)

Known-knowns
--

It's currently not possible to search for links in the `pinboard` core using
machine tags because some of the characters used to encode machine tags are
reserved in Solr/Lucene land. This will worked out eventually.

See also
--

* [the pinboard.in export bookmarks/tweets page](https://pinboard.in/export/)
