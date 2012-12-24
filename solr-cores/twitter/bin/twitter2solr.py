#!/usr/bin/env python

import sys
import pysolr
import json
import logging

def import_tweets(solr_endpoint, tweets):

    solr = pysolr.Solr(solr_endpoint)

    fh = open(tweets, 'r')

    data = json.load(fh)
    docs = []

    for doc in data['tweets']:

        doc['username'] = data['twitter_account']

        for key in ('created_at', 'added_at') :
            doc[ key ] = 'T'.join(doc[ key ].split(' ')) + 'Z'

        del(doc['source'])
        docs.append(doc)
        
        if len(docs) == 100:
            solr.add(docs)
            docs = []

    if len(docs):
        solr.add(docs)
    
    solr.optimize()

if __name__ == '__main__':

    import optparse

    parser = optparse.OptionParser()
    parser.add_option("-t", "--tweets", dest="tweets", action="store", help="your tweets (as a pinboard.in JSON export files)")
    parser.add_option("-s", "--solr", dest="solr", action="store", help="your solr endpoint; default is http://localhost:8983/solr/twitter", default="http://localhost:8983/solr/twitter")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", help="enable chatty logging", default=False)

    (opts, args) = parser.parse_args()

    if opts.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    import_tweets(opts.solr, opts.tweets)

    logging.info("all done!")
    sys.exit()

