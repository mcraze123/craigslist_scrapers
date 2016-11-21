#!/usr/bin/perl -w
#
# Craigslist Housing Finder
# Parses craigslist rss feeds and prints houses listed today
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
	'http://knoxville.craigslist.org/search/apa?format=rss'
);

my @search_terms=(
	qr{condo}xmi,
	qr{house}xmi,
	qr{farragut}xmi,
	qr{fountain\s+city}xmi,
	qr{inskip}xmi,
	qr{knox}xmi,
	qr{townhouse}xmi,
	qr{\d{4,}ft}xmi,
	qr{[23456789]\s*(br|bedroom)}xmi
);

my @not_search_terms=(
	qr{andersonville}xmi,
	qr{\s*apt\s*}xmi,
	qr{apartment}xmi,
	qr{corryton}xmi,
	qr{(dbl|double)\s*wide}xmi,
	qr{kingston}xmi,
	qr{mobile\s+home}xmi,
	qr{norris}xmi,
	qr{roane}xmi,
	qr{sevier}xmi
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
		my $today=localtime->strftime('%Y-%m-%d');
		
		#$today="2015-03-27";
		if ($posted_date =~ /^$today/){
			# convert utf8 characters to ascii
			$title =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
			$title =~ s/&\#x0024;(\d+)/\$$1/g; # Convert decoded price to ascii
			$description =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
			
			my $not_search_flag=0;
			for my $term (@not_search_terms){
				if($title =~ m{$term}i){
					$not_search_flag=1;
					last;
				}
			}
			next if $not_search_flag;

			for my $term (@search_terms){
				if($title =~ m{$term}i){
					# Get the image links and the full description
					my $m = WWW::Mechanize->new( agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17');
					$m->get($url);
					next if($m->content !~ m/(http:\/\/images\.craigslist\.org\/[A-Z0-9]+_[A-Za-z0-9]+_600x450\.jpg)/);

					my $full_description="";
					if($m->content =~ m/<section\s+id=\"postingbody\">(.*?)<\/section>/is){
						$full_description = $1;
						$full_description =~ s/<.+>//g;
						$full_description =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
						$full_description =~ s/\*//g;
					}
	
					print "$title\n";
					print "$url\n";
					if($full_description eq ""){
						print "  $description\n\n";
					}
					else{
						print "  $full_description\n\n";
					}
					print "========================================================\n\n";
					last;
				}
			}
		}
	}
}

exit;

__END__

