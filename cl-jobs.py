#!/usr/bin/python
#
# Craigslist job finder
# &copy; Michael Craze -- http://projectcraze.us.to
#

import feedparser

feeds=[
'https://knoxville.craigslist.org/search/sof?format=rss',#software/qa/dba
'http://knoxville.craigslist.org/search/eng?format=rss',#internet eng
'http://knoxville.craigslist.org/search/sad?format=rss',#systems/networking #Causes not an array reference bug
'http://knoxville.craigslist.org/search/tch?format=rss',#tech support
'http://knoxville.craigslist.org/search/web?format=rss',#web/info design
'http://knoxville.craigslist.org/search/cpg?format=rss' #computer gigs
]

for f in feeds:
    #print f
    d = feedparser.parse(f)
    for post in d.entries:
        title=post.title.encode('ascii','replace')
        link=post.link.encode('ascii','replace')
        description=post.description.encode('ascii','replace')
        print title + "\n\n"
        print " " + link + "\n\n"
        print " " + description + "\n\n\n"
        print "========================================================\n\n\n:"

