#!/usr/bin/perl -w
#
# craigslist finder
# &copy; Michael Craze -- http://projectcraze.us.to

use strict;
use XML::Simple;
use LWP::Simple;
use Data::Dumper;

my $debug = 0;

my @feeds = (
		'http://knoxville.craigslist.org/search/zip?format=rss'
);

for my $feed (@feeds){
	my $xml = get($feed);
	my $ref = XMLin($xml);
	my $items = $ref->{item};

	if ($debug){
		print "$xml";
		print Data::Dumper->Dump([$items]);
		exit;
	}

	for my $item (@$items){
		my $title = $item->{title};
		my $url = $item->{link};

		if ($title =~ /tv/i){
			print "$title\n  $url\n\n";
		}
	}
# don't suck feeds too quickly
	sleep 2;
}

exit;

__END__

