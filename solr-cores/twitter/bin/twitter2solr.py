#!/usr/bin/env python

import sys
import pysolr
import json

if __name__ == '__main__':

    solr = pysolr.Solr('http://localhost:8983/solr/twitter')

    path = sys.argv[1]
    fh = open(path, 'r')

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

