#!/usr/bin/env python

# THIS IS SO NOT FINISHED YET (20121225/straup)

# curl 'http://localhost:8983/solr/pinboard/select?q=tags%3Ahighlights&fq=machinetags%3Adt8cyear8e2012&sort=_version_+desc&rows=800&fl=description%2C+extended&wt=json' > highlights.json

# http://localhost:8983/solr/pinboard/select?q=tags%3Ahighlights+AND+extended%3A*+AND+time%3A[2012-01-01T00%3A00%3A00Z+TO+2012-12-31T23%3A59%3A59Z]&fq=-machinetags%3Adt8cyear8e2011&sort=_version_+desc&rows=800&fl=description%2C+extended%2Ctime&wt=xml

# wkpdf -o highlights.pdf -s highlights.html -p custom:432x648 -m 54 36 72 36
 
import sys
import json

path = sys.argv[1]
fh = open(path, 'r')
data = json.load(fh)

print """
<html>
	<head>
		<title></title>
		<style type="text/css">
body {
font-family:sans-serif;
font-weight:100;
font-size:12pt;
/* margin: 3em; */
margin: 0;
}

blockquote {
margin-bottom: 3em;
clear:all;
}

blockquote p {
line-height: 1.5em;
}

cite {
font-size: 8pt;	
line-height: 1.4em;
}
		</style>
	</head>
	<body>
"""

for doc in data['response']['docs']:

    if not doc.get('extended'):
        continue

    print '<blockquote class="highlight">'

    for p in doc['extended'].split('\n\n'):
        print '<p class="blurb">'
        print p.encode('ascii', 'ignore')
        print '</p>'

    parts = doc['description'].split(" # ")

    print '<cite>'
    print parts[0]

    parts = parts[1].split(" | ")
    print '<br />'
    print parts[-1].replace("Added on ", "")

    print '</cite>'
    print '</blockquote>'

print """
	</body>
</html>
"""

sys.exit()

