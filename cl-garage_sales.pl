#!/usr/bin/perl -w
#
# Craigslist Garage Sale Finder
# Parses craigslist rss feeds and prints garage sales listed yesterday and today
# &copy; Michael Craze -- http://projectcraze.us.to
#
# TODO:
#	-use quoted regex
#	-only search for estate sales, and neighborhood/family/community yard sales

use strict;
use XML::Simple;
use LWP::Simple;
use Data::Dumper;
use WWW::Mechanize;
use Time::Piece;
use Time::Seconds;
use utf8;
use Text::Unidecode;

my @feeds = (
	'http://knoxville.craigslist.org/search/gms?format=rss'
);

my @search_terms=(
	qr{community}mi,
	qr{estate}mi,
	qr{family}mi,
	qr{moving}mi,
	qr{multi}mi,
	qr{neighborhood}mi
);

for my $feed (@feeds){
	my $xml = get($feed);
	my $ref = XMLin($xml);
	my $items = $ref->{item};
	
	for my $item (@$items){
		my $url = $item->{'link'};
		my $title = $item->{'title'};
		my $posted_date = $item->{'dc:date'};
		my $description = $item->{'description'};

		#this is stupid
		my $today=localtime->strftime('%Y-%m-%d');
		my $now = localtime();
		my $yesterday=$now - ONE_HOUR*($now->hour+12);
		$yesterday=$yesterday->strftime('%Y-%m-%d');
		#$today="2015-02-28";
		if ($posted_date =~ /^$today/ || $posted_date =~ /^$yesterday/){
			# convert utf8 characters to ascii
			$title =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
			$description =~ s/([^[:ascii:]]+)/unidecode($1)/ge;

			# Check if any terms we want are in the title
			my $matched_flag=0;
			for my $term (@search_terms){
				if($title =~ m{$term}i){
					$matched_flag=1;
					last;
				}
			}
			if($matched_flag==0){ next; }

			# Get the image links and the full description
			my $m = WWW::Mechanize->new( agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17');
			$m->get($url);
			#my @image_links = ($m->content =~ m/(http:\/\/images\.craigslist\.org\/[A-Z0-9]+_[A-Za-z0-9]+_600x450\.jpg)/g);

			my $full_description="";
			if($m->content =~ m/<section\s+id=\"postingbody\">(.*?)<\/section>/is){
				$full_description = $1;
				$full_description =~ s/<.+>//g;
				$full_description =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
				$full_description =~ s/\*//g;
			}



			print "$title\n";
			print "$url\n";
			#print "  $description\n\n";
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

