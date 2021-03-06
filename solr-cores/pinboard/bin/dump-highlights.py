#!/usr/bin/env python

import cgi 
import sys
import json
import pysolr
import logging
import dateutil.parser

def dump_highlights(opts):

    if opts.output:
        fh = open(opts.output, 'w')
    else:
        fh = sys.stdout

    solr = pysolr.Solr(opts.solr)
    year = opts.year

    write_header(fh, opts.title)

    total = None
    rows = 1000
    start = 0

    query = [
        "tags:highlights",
        "extended:*"
        ]

    if opts.year:
        query.append("time:[ %s-01-01T00:00:00Z TO %s-12-31T23:59:59Z ]" % (opts.year, opts.year))

    query = " AND ".join(query)

    args = {
        'q' : query,
        'sort' : 'time asc',
        'fl': 'description,extended,href,hostname,time',
        'rows': rows,
        }

    if opts.filter:
        args['fq'] = opts.filter

    data = []

    while not total or start < total:

        args['start'] = start
        
        rsp = solr.search(**args)

        if not total:
            total = rsp.hits

        if total == 0:
            break

        for doc in rsp.docs:
            write_highlight(fh, doc)

        start += rows

    write_footer(fh)

def write_header(fh, title=''):

    fh.write("""<!DOCTYPE html><html><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8"><title></title><style type="text/css">
body { font-family:sans-serif; font-weight:100; font-size:12pt; margin: 0; }
    blockquote { margin-bottom: 1.5em;}
blockquote p { line-height: 1.5em; }
cite { font-size: 8pt; line-height: 1.4em; }
#titlepage { font-size:36pt; text-align:right; font-weight:700; margin-top: 10em; color:#666; }
.blank { page-break-after: always; }
		</style></head><body><div class="blank" id="titlepage">%s</div><div class="blank">&#160;</div>""" % title)

def write_footer(fh):
    fh.write("</body></html>")

def write_highlight(fh, doc):

    fh.write('<blockquote class="highlight">')

    for p in doc['extended'].split('\n\n'):
        fh.write('<p class="blurb">')
        fh.write(cgi.escape(p.encode('utf8')))
        fh.write('</p>')

    parts = doc['description'].split(" #")

    fh.write('<cite>')
    fh.write(cgi.escape(parts[0].encode('utf8')))

    if doc['hostname'] == 'kindle.amazon.com':

        if len(parts) == 2:
            parts = parts[1].split(" | ")
            fh.write(parts[-1].replace("Added on ", " - "))

    else:

        fmt = "%A, %B %d, %Y, %I:%M %p"
        dt = dateutil.parser.parse(doc['time'])
    
        fh.write(" - %s" % dt.strftime(fmt).encode('utf8'))

        # maybe... dunno... probably need to add an index at
        # the back or something... (20140105/straup)

        # parts = doc['href'].split("#")
        # fh.write('<br />')
        # fh.write(cgi.escape(parts[0].encode('utf8')))

    fh.write('</cite>')
    fh.write('</blockquote>')

if __name__ == '__main__':

    # ./dump-highlights.py -y 2012 -f '-machinetags:dt8cyear8e2011' | wkpdf -o foop.pdf -p custom:432x648 -m 54 36 72 36
    # ./dump-highlights.py -f 'machinetags:dt8cyear8e2011' | wkpdf -o foop.pdf -p custom:432x648 -m 54 36 72 36

    import optparse

    parser = optparse.OptionParser()
    parser.add_option("-y", "--year", dest="year", action="store", help="", default=None)
    parser.add_option("-f", "--filter", dest="filter", action="store", help="", default=None)
    parser.add_option("-t", "--title", dest="title", action="store", help="", default='')
    parser.add_option("-o", "--output", dest="output", action="store", help="", default=None)
    parser.add_option("-s", "--solr", dest="solr", action="store", help="your solr endpoint; default is http://localhost:8983/solr/pinboard", default="http://localhost:8983/solr/pinboard")
    parser.add_option("-v", "--verbose", dest="verbose", action="store_true", help="enable chatty logging", default=False)

    (opts, args) = parser.parse_args()

    if opts.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    dump_highlights(opts)

    logging.info("done")
    sys.exit()
