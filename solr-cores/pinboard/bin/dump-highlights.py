#!/usr/bin/env python

# THIS IS SO NOT FINISHED YET (20121225/straup)

# wkpdf -o highlights.pdf -s highlights.html -p custom:432x648 -m 54 36 72 36
 
import sys
import json
import pysolr
import pprint

def write_header(fh, title=''):

    fh.write("""<html><head><title></title><style type="text/css">
body { font-family:sans-serif; font-weight:100; font-size:12pt; margin: 0; }
blockquote { margin-bottom: 3em;}
blockquote p { line-height: 1.5em; }
cite { font-size: 8pt; line-height: 1.4em; }
		</style></head><body>""")

def write_footer(fh):
    fh.write("</body></html>")

def write_highlight(fh, doc):

    fh.write('<blockquote class="highlight">')

    for p in doc['extended'].split('\n\n'):
        fh.write('<p class="blurb">')
        fh.write(p.encode('ascii', 'ignore'))
        fh.write('</p>')

    parts = doc['description'].split(" # ")

    fh.write('<cite>')
    fh.write(parts[0])

    if len(parts) == 2:

        parts = parts[1].split(" | ")

        fh.write('<br />')
        fh.write(parts[-1].replace("Added on ", ""))

    else:
        # FIX ME: format doc['time'] ...
        pass

    # fh.write("<br />%s" % ", ".join(doc['tags']))

    fh.write('</cite>')
    fh.write('</blockquote>')

if __name__ == '__main__':

    fh = sys.stdout

    write_header(fh)

    solr = pysolr.Solr('http://localhost:8983/solr/pinboard/')

    year = 2012

    total = None
    rows = 1000
    start = 0

    query = [
        "tags:highlights",
        "extended:*",
        "time:[ %s-01-01T00:00:00Z TO %s-12-31T23:59:59Z ]" % (year, year)
        ]

    query = " AND ".join(query)

    filter = '-machinetags:dt8cyear8e%s' % (year - 1)

    args = {
        'q' : query,
        'sort' : '_version_ desc',
        'fl': 'description,extended,tags,time',
        'rows': rows,
        }

    if filter:
        args['fq'] = filter

    data = []

    while not total or start < total:

        args['start'] = start
        
        rsp = solr.search(**args)

        if not total:
            total = rsp.hits

        for doc in rsp.docs:
            write_highlight(fh, doc)

        start += rows

    write_footer(fh)

sys.exit()
