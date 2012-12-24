#!/usr/bin/env python

import sys
import logging
import pysolr
import json

def import_links(solr_endpoint, pinboard_links):

    solr = pysolr.Solr(solr_endpoint)

    fh = open(pinboard_links, 'r')

    data = json.load(fh)
    docs = []

    for doc in data:

        doc['tags'] = doc['tags'].split(' ')

        """
        tags = []

        for t in doc['tags'].split(' '):

            parts = []

            head = t.split(":")
            parts.append(head[0])

            if len(head) == 2:
                tail = head[1].split("=")
                parts.extend(tail)

            if len(parts):
                parts = "/".join(parts)
                tags.append(parts)

        if len(tags):
            doc['tags'] = tags
        """

        for key in ('shared', 'toread'):
            if doc[ key ] == 'yes':
                doc[ key ] = True
            else:
                doc[ key ] = False

        if doc['description'] == '':
            doc['description'] = doc['href']

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

    (opts, args) = parser.parse_args()

    if opts.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    import_links(opts.solr, opts.pinboard)

    logging.info("all done!")
    sys.exit()
