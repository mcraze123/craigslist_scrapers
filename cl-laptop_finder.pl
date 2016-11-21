#!/usr/bin/perl -w
#
# Craigslist Laptop Finder
# &copy; Michael Craze -- http://projectcraze.us.to

use strict;
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
my $log_file="/home/mike/code/craigslist/laptop_finder.log";

my @feeds=(
		'http://knoxville.craigslist.org/search/sya?format=rss'
);

# If these terms are found then the listing will be printed
my @search_terms=(
	qr{acer}xmi,
	qr{apple}xmi,
	qr{aspire}xmi,
	qr{asus}xmi,
	qr{book}xmi,
	qr{broken}xmi,
	qr{commodore}xmi,
	qr{dell}xmi,
	qr{eee}xmi,
	#qr{elitebook}xmi,
	qr{envy}xmi,
	qr{extensa}xmi,
	qr{gateway}xmi,
	qr{hp}xmi,
	qr{ideapad}xmi,
	qr{inspiron}xmi,
	qr{kaypro}xmi,
	qr{laptop}xmi,
	qr{latitude}xmi,
	qr{lenovo}xmi,
	#qr{lifebook}xmi,
	qr{mac}xmi,
	#qr{macbook}xmi,
	#qr{macintosh}xmi,
	#qr{netbook}xmi,
	#qr{notebook}xmi,
	#qr{omnibook}xmi,
	qr{parts}xmi,
	qr{pavilion}xmi,
	qr{precision}xmi,
	qr{repair}xmi,
	qr{satellite}xmi,
	qr{studio}xmi,
	qr{tablet}xmi,
	qr{tandy}xmi,
	qr{thinkpad}xmi,
	qr{toshiba}xmi,
	#qr{toughbook}xmi,
	qr{travelmate}xmi,
	#qr{vaio}xmi, # Sony no longer makes laptops, this should probably be removed
	qr{vostro}xmi,
	qr{xps}xmi
	#qr{zenbook}xmi
);

# If these terms are found, then the lising will be skipped
my @not_search_terms=(
	qr{aio}xmi,
	qr{all([- ]+)in([- ]+)one}xmi,
	qr{bag}xmi,
	qr{buy}xmi,
	qr{case}xmi,
	qr{desktop}xmi,
	qr{desk}xmi,
	qr{docking\s*station}xmi,
	qr{g4}xmi,
	qr{imac}xmi,
	qr{i-mac}xmi,
	qr{keyboard}xmi,
	qr{looking}xmi,
	qr{mhz}xmi,
	qr{monitor}xmi,
	qr{need}xmi,
	qr{nook}xmi,
	qr{officejet}xmi,
	qr{optiplex}xmi,
	qr{p\.?\s*cs?}xmi, # This was just 'pc' but I had to personalize it to match 'P. Cs' to get rid of some idiot's incessant posts
	qr{p(2|3|ii|iii)}xmi,
	qr{powerbook}xmi,
	qr{powermac}xmi,
	qr{printer}xmi,
	qr{purchase}xmi,
	qr{replicator}xmi,
	qr{sales}xmi,
	qr{scan\s*jet}xmi,
	qr{service}xmi,
	qr{server}xmi,
	qr{setup}xmi,
	qr{scanner}xmi,
	qr{tower}xmi,
	qr{trade}xmi,
	qr{wanted}xmi,
	qr{wtb}xmi,
	qr{xp}xmi
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
		
		# Get the craigslist page
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
				# Convert UTF8 characters to ascii
				$title =~ s/([^[:ascii:]]+)/unidecode($1)/ge;
				$title =~ s/&\#x0024;(\d+)/\$$1/g; # Convert decoded price to ascii
				$description =~ s/([^[:ascii:]]+)/unidecode($1)/ge;

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

