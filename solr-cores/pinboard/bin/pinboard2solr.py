#!/usr/bin/env python

import sys
import pysolr
import json

if __name__ == '__main__':

    solr = pysolr.Solr('http://localhost:8983/solr/pinboard')

    path = sys.argv[1]
    fh = open(path, 'r')

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
    
    solr.optimize()

