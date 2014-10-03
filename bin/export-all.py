#!/usr/bin/env python

import sys
import logging
import urllib
import urllib2

import os.path
import optparse
import ConfigParser

if __name__ == '__main__':

    parser = optparse.OptionParser()
    parser.add_option("--config", dest="config", default=None, help="A valid .ini config file containing your pinboard.in user token.")
    parser.add_option("--output", dest="output", default=None, help="The path of the file to write bookmarks to. Default is STDOUT.")
    parser.add_option("--verbose", dest="verbose", default=False, action="store_true", help="Be chatty.")

    (opts, args) = parser.parse_args()

    if opts.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)
        
    if not os.path.exists(opts.config):
        logging.error("%s does not exist" % opts.config)
        sys.exit()

    cfg = ConfigParser.ConfigParser()
    cfg.read(opts.config)

    output = sys.stdout

    if opts.output:

        if not os.path.exists(opts.output):
            logging.error("%s does not exist" % opts.output)
            sys.exit()

        try:
            output = open(opts.output, "w")
        except Exception, e:
            logging.error("failed to open %s, because %s" % (opts.output, e))
            sys.exit()
            
    token = cfg.get('pinboard', 'token')

    query = {
        'format': 'json',
        'auth_token': token
        }
    
    query = urllib.urlencode(query)
    url = 'https://api.pinboard.in/v1/posts/all?' + query

    try:
        rsp = urllib2.urlopen(url)
    except Exception, e:
        logging.error(e)
        sys.exit()

    output.write(rsp.read())
    sys.exit()
