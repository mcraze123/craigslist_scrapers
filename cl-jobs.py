#!/usr/bin/python
#
# Craigslist job finder
# &copy; Michael Craze -- http://projectcraze.us.to
#

from time import gmtime, strftime
import feedparser

feeds=[
'https://knoxville.craigslist.org/search/sof?format=rss',#software/qa/dba
'http://knoxville.craigslist.org/search/eng?format=rss',#internet eng
'http://knoxville.craigslist.org/search/sad?format=rss',#systems/networking #Causes not an array reference bug
'http://knoxville.craigslist.org/search/tch?format=rss',#tech support
'http://knoxville.craigslist.org/search/web?format=rss',#web/info design
'http://knoxville.craigslist.org/search/cpg?format=rss' #computer gigs
]

now=strftime("%Y-%m-%d %H:%M:%S", gmtime())
print now + "\n\n"

for f in feeds:
    d=feedparser.parse(f)
    print "---[[[[" + d.feed.title + "]]]]---\n\n"
    for post in d.entries:
        title=post.title.encode('ascii','replace')
        link=post.link.encode('ascii','replace')
        description=post.description.encode('ascii','replace')
        date=post.date
        print " " + date + "\n\n"
        print " " + title + "\n\n"
        print "\t" + link + "\n\n"
        print "\t" + description + "\n\n\n"
        print "========================================================\n\n\n"
    print "========================================================\n\n\n"

