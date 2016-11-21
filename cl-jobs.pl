#!/usr/bin/perl -w
#
# Craigslist Job Finder
# Parses craigslist rss feeds and prints jobs listed today
# &copy; Michael Craze -- http://projectcraze.us.to

use strict;
use XML::Simple;
use LWP::Simple;
use Data::Dumper;
use WWW::Mechanize;
use Time::Piece;
use utf8;
use Text::Unidecode;

my @feeds = (
	'https://knoxville.craigslist.org/search/sof?format=rss',#software/qa/dba
	'http://knoxville.craigslist.org/search/eng?format=rss',#internet eng
#	'http://knoxville.craigslist.org/search/sad?format=rss',#systems/networking # Causes not an array reference bug
	'http://knoxville.craigslist.org/search/tch?format=rss',#tech support
	'http://knoxville.craigslist.org/search/web?format=rss',#web/info design
	'http://knoxville.craigslist.org/search/cpg?format=rss' #computer gigs
);

my @skip_post_terms=(
	qr{[-0-9 \$]+}m,
	qr{[~=*|]+}m,
	qr{affiliate}mi,
	qr{agent}mi,
	qr{an\+\+\+}mi, # Gets rid of a plastic surgery office looking for a secretary
	qr{calls}mi,
	qr{commission}mi,
	qr{csr}mi,
	qr{customer\s+support}mi,
	qr{extra\s+income}mi,
	qr{hvac}mi,
	qr{leads}mi,
	qr{marketing}mi,
	qr{part\s+time}mi,
	qr{phone}mi,
	qr{((?!tech).*?sale)|(sale.*?(?!tech))}mi,
	qr{sign}mi,
	qr{survey}mi
);

for my $feed (@feeds){
	my $xml = get($feed);
	my $ref = XMLin($xml);
	my $items = $ref->{item};
	#print $xml;
	#print Dumper($items);

	for my $item (@$items){
		my $url = $item->{'link'};
		my $title = $item->{'title'};
		my $posted_date = $item->{'dc:date'};
		my $description = $item->{'description'};
		my $today=localtime->strftime('%Y-%m-%d');
		my $skip_post_flag=0;
		#print "$title\n";

		#$today="2015-04-23";
		if ($posted_date =~ /^$today/){
			#print "Posted Today\n";
			# convert utf8 characters to ascii
			$title =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
			$description =~ s/([^[:ascii:]]+)/unidecode($1)/ge;

			# Remove other unwanted crap
			$description =~ s/<.+>//g;
			$description =~ s/`//g;
			$description =~ s/\\//g;
			$description =~ s/&\#?[a-zA-Z0-9]+;//g;
			$description =~ s/;//g;
			$description =~ s/\*//g;
		
			# Check if any terms we don't want are in the title
			for my $term (@skip_post_terms){
				if($title =~ m{$term}i){
					$skip_post_flag=1;
					last;
				}
			}
			next if $skip_post_flag;

			# Get the image links and the full description
			my $m = WWW::Mechanize->new( agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17');
			$m->get($url);
			#my @image_links = ($m->content =~ m/(http:\/\/images\.craigslist\.org\/[A-Z0-9]+_[A-Za-z0-9]+_600x450\.jpg)/g);

			my $full_description="";
			if($m->content =~ m/<section\s+id=\"postingbody\">(.*?)<\/section>/is){
				$full_description = $1;
				$full_description =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
				$full_description =~ s/<.+>//g;
				$full_description =~ s/`//g;
				$full_description =~ s/\\//g;
				$full_description =~ s/&\#?[a-zA-Z0-9]+;//g;
				$full_description =~ s/;//g;
				$full_description =~ s/\*//g;
			}

			print "$title\n";
			print "$url\n";
			#for my $image (@image_links){
			#	print " $image\n";
			#}
			if($full_description eq ""){
				print "  $description\n\n";
			}
			else{
				print "  $full_description\n\n";
			}
			print "========================================================\n\n";
		}
	}
}

exit;

__END__

