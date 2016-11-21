#!/usr/bin/perl -w
#
# Craigslist Broken TV Finder
# &copy; Michael Craze -- http://projectcraze.us.to

use strict;
use warnings;
use XML::Simple;
use LWP::Simple;
use Data::Dumper;
use WWW::Mechanize;
use utf8;
use Text::Unidecode;

my $MAX_AMOUNT=200; #in USD
my $skip_one_dollar_posts=1;
my $skip_posts_with_no_pictures=1;
my $skip_posts_over_200_dollars=1;
my $log_file="/home/mike/code/craigslist/tv_finder.log";

my @feeds=(
		'http://knoxville.craigslist.org/search/ela?format=rss'
);

# If these terms are found then the listing will be printed
my @search_terms=(
	qr{broken}xmi,
	qr{flat[- ]*screen}xmi,
	qr{lcd}xmi,
	qr{o?led}xmi,
	qr{parts}xmi,
	qr{plasma}xmi,
	qr{repair}xmi,
	qr{television}xmi,
	qr{tv}xmi
);

# If these terms are found, then the lising will be skipped
my @not_search_terms=(
	qr{antenna}xmi,
	qr{buy}xmi,
	qr{cash\s+for}xmi,
	qr{color}xmi,
	qr{combo}xmi,
	qr{crt}xmi,
	qr{desk}xmi,
	qr{direct}xmi,
	qr{dlp}xmi,
	qr{dtv}xmi,
	qr{dvd}xmi,
	qr{looking}xmi,
	qr{monitor}xmi,
	qr{mount}xmi,
	qr{need}xmi,
	qr{purchase}xmi,
	qr{(rear[- ]*)?projection}xmi,
	qr{sales}xmi,
	qr{service}xmi,
	qr{trade}xmi,
	qr{tube}xmi,
	qr{vcr}xmi,
	qr{wall\s+mount}xmi,
	qr{wanted}xmi,
	qr{wtb}xmi
);

my @urls_seen=();
open my $ILFH, '<', $log_file or die "Can't open $log_file: $!\n";
chomp(my @postings=<$ILFH>);
close $ILFH;

for my $feed (@feeds){
	my $xml = get($feed);
	my $ref = XMLin($xml);
	my $items = $ref->{item};

	for my $item (@$items){
		my $url = $item->{link};
		my $title = $item->{title};
		my $posted_date = $item->{'dc:date'};
		my $description = $item->{'description'};
		my $not_search_flag=0;
		my $already_seen_flag=0;
		
		# Keep track of current feed's urls so we can write them to the log
		push(@urls_seen,$url);

		# Skip if item is listed for $1
		if($skip_one_dollar_posts){
			next if $title =~ /&\#x0024;1/;
		}
		
		# Skip if item is listed for more than 200
		if($skip_posts_over_200_dollars){
			if ($title =~ m/&\#x0024;(\d+)/) {
				next if $1 > $MAX_AMOUNT;
			}
		}

		# Check if we have aleady seen the post
		for my $post (@postings){
			if($url =~ /$post/){
				$already_seen_flag=1;
				last;
			}
		}
		next if $already_seen_flag;

		# Check if any terms we don't want are in the title
		for my $term (@not_search_terms){
			if($title =~ m{$term}i){
				$not_search_flag=1;
				last;
			}
		}
		next if $not_search_flag;
		
		# Get the craigslist ad's page
		my $m = WWW::Mechanize->new( agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17');
		$m->get($url);

		# Check if there is at least one image that the poster put on the post
		my @image_links = ($m->content =~ m/(http:\/\/images\.craigslist\.org\/[A-Z0-9]+_[A-Za-z0-9]+_600x450\.jpg)/g);
		if($skip_posts_with_no_pictures){
			next if scalar @image_links == 0;
		}

		# Check if the post has any words we are looking for
		for my $term (@search_terms){
			if($title =~ m{$term}i){
				# Convert decoded price to ascii
				$title =~ s/&\#x0024;(\d+)/\$$1/g;

				# Convert UTF8 characters to ascii
				$title =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
				$description =~ s/([^[:ascii:]]+)/unidecode($1)/ge;

				##  The following was moved outside of the loop, so that we can go ahead and skip any post that doesn't have pictures.
				## Get the image links and the full description
				#my $m = WWW::Mechanize->new( agent => 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.60 Safari/537.17');
				#$m->get($url);
				#my @image_links = ($m->content =~ m/(http:\/\/images\.craigslist\.org\/[A-Z0-9]+_[A-Za-z0-9]+_600x450\.jpg)/g);
				
				my $full_description="";
				if($m->content =~ m/<section\s+id=\"postingbody\">(.*?)<\/section>/is){
					$full_description = $1;
					$full_description =~ s/<.+>//g;
					$full_description =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
					$full_description =~ s/\*//g;
				}

				# Print what we found
				print "$posted_date\n";
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

				last;
			}
		}
	}
}

# Write new log file 
open my $OLFH, '>', $log_file or die "Can't open $log_file: $!\n";
for my $url (@urls_seen){
	print $OLFH "$url\n";
}
close $OLFH;

exit;

__END__

