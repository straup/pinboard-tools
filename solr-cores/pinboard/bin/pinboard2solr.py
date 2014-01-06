#!/usr/bin/env python

import sys
import logging
import pysolr
import json
import machinetag
import urlparse
import datetime

def import_links(options):

    solr = pysolr.Solr(options.solr)

    if options.purge:
        logging.info("purging all existing bookmarks...")
        solr.delete(q='*:*')

    fh = open(options.pinboard, 'r')

    data = json.load(fh)
    docs = []

    for doc in data:

        tags = []
        machinetags = []
        machinetags_hierarchy = []

        for t in doc['tags'].split(' '):

            tags.append(t)

            mt = machinetag.machinetag(t)

            if not mt.is_machinetag():
                continue

            if mt.namespace() == 'dt' and mt.predicate() == 'timestamp':

                ts = float(mt.value())
		dt = datetime.datetime.fromtimestamp(ts)
		time = dt.strftime('%Y-%m-%dT%H:%M:%SZ')

		doc['time'] = time
                continue

            for chunk in mt.magic_8s():
                if not chunk in machinetags:
                    machinetags.append(chunk)

            hier = [
                mt.namespace(),
                mt.predicate(),
                mt.value()
                ]

            hier = map(unicode, hier)
            hier = "/".join(hier)

            machinetags_hierarchy.append(hier)

        if len(tags):
            doc['tags'] = tags

        if len(machinetags):
            doc['machinetags'] = machinetags
            doc['machinetags_hierarchy'] = machinetags_hierarchy

        for key in ('shared', 'toread'):
            if doc[ key ] == 'yes':
                doc[ key ] = True
            else:
                doc[ key ] = False

        if doc['description'] == '':
            doc['description'] = doc['href']

        parsed = urlparse.urlparse(doc['href'])
        hostname = parsed.hostname

        if hostname:
            if hostname.startswith("www."):
                hostname = hostname.replace("www.", "")
        
        doc['hostname'] = hostname

        docs.append(doc)
        
        if len(docs) == 1000:
            solr.add(docs)
            docs = []

    if len(docs):
        solr.add(docs)
    
    logging.debug("import complete, optimizing...")
    solr.optimize()


if __name__ == '__main__':

    import optparse

    parser = optparse.OptionParser()
    parser.add_option("-p", "--pinboard", dest="pinboard", action="store", help="your pinboard.in links (as a JSON export)")
    parser.add_option("-s", "--solr", dest="solr", action="store", help="your solr endpoint; default is http://localhost:8983/solr/pinboard", default="http://localhost:8983/solr/pinboard")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", help="enable chatty logging", default=False)
    parser.add_option("--purge", dest="purge", action="store_true", help="purge all your existing bookmarks before starting the import; default is false", default=False)

    (opts, args) = parser.parse_args()

    if opts.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    import_links(opts)

    logging.info("all done!")
    sys.exit()
