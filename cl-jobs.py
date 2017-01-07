#!/usr/bin/python
#
# Craigslist job finder
# &copy; Michael Craze -- http://projectcraze.us.to
#

from time import gmtime, strftime
import feedparser
import urllib2
import re

feeds=[
'https://knoxville.craigslist.org/search/sof?format=rss',#software/qa/dba
'http://knoxville.craigslist.org/search/eng?format=rss',#internet eng
'http://knoxville.craigslist.org/search/sad?format=rss',#systems/networking #Causes not an array reference bug
'http://knoxville.craigslist.org/search/tch?format=rss',#tech support
'http://knoxville.craigslist.org/search/web?format=rss',#web/info design
'http://knoxville.craigslist.org/search/cpg?format=rss' #computer gigs
]

# Get today's date
today=strftime("%Y-%m-%d", gmtime())
#print today + "\n"

for f in feeds:
    d=feedparser.parse(f)

    # Print title if there is a job posted today in the feed
    for post in d.entries:
        matches=re.search(r"%s" % today,post.date,re.M|re.I)
        if matches is not None:
            print "---[[[[" + d.feed.title + "]]]]---\n"
            break

    # Print the jobs posted today
    for post in d.entries:
        title=post.title.encode('ascii','replace')
        link=post.link.encode('ascii','replace')
        description=post.description.encode('ascii','replace')

        date=post.date
        matches=re.search(r"%s" % today,date,re.M|re.I)
        if matches is not None:
            print " " + date + "\n"
            print " " + title + "\n"
            print "\t" + link + "\n"

            # Get full desctiption
            response=urllib2.urlopen(link)
            html=response.read()
            body_rx=re.compile('<section id="postingbody">(.*?)</section>',re.I|re.M|re.S)
            matches=body_rx.search(html)
            description= matches.group(1)
            description=re.sub(r'<.*?>',"",description)
            print description + "\n\n" # doesn't print full description

            print "========================================================\n\n"
