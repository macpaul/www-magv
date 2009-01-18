#!/usr/bin/perl
# usage:
#	Find a magazine from magazine list: 
#		mirror_magv.pl username password find [magazine_name]
#
#	List all available versions of a magazine: 
#		mirror_magv.pl username password listver [magazine_name] 
#
#	Download all/single version of a magazine:
#		mirror_magv.pl username password download [magazine_name] [all/version_number] 
#

use strict;
use warnings;
use utf8;
use Switch;
use lib './';
use MAGV;

my $numArgs = $#ARGV + 1;

my $username = $ARGV[0];	#account
my $password = $ARGV[1];	#password
my $command = $ARGV[2];		#control command: [find download list]
my $q_book_name = $ARGV[3];	#chinese name
my $q_book_ver = $ARGV[4];	#all=mirror all

login($username, $password);

switch ($command) {
	my $match_book_list = search_book($q_book_name);

	case "find" {
		my $count=0;

		foreach my $item (@$match_book_list) {
			my $out_string;
			$out_string = sprintf "Mag_%03d: %s, url: http://www.magv.com/%s\n", $count++, $item->{'name'}, $item->{'url'};
			print $out_string;
		}
	}

	case "download" {
		my $pagecount=0;
		my $book_ver_info; 
		my $book_ver_info_page;
		my $item;
		my $mdid;

		my @match_book_index = @$match_book_list;

		# list the vers of book
		if ( $#match_book_index==0 ) {	#only one match
			$item = shift @$match_book_list ;
			if ( $item->{'url'} =~ m{mdid=([0-9]*)} ) {
				$mdid=$1;
			}

			$book_ver_info_page = list_book_vers_page($mdid, $pagecount);

			while ( defined ($book_ver_info_page) ) {
				foreach my $item (@$book_ver_info_page) {
					push @$book_ver_info, $item;
				}

				$pagecount++;
				$book_ver_info_page = list_book_vers_page($mdid, $pagecount);
			}
		} else { 
			print "More than one kind of magazines.\n";
		}

		if ($q_book_ver=='all') {
			foreach my $item (@$book_ver_info) {
				download( $item->{'book_id'},
					$item->{'book_ver'},
					$item->{'book_date'},
					$item->{'abs_img_dir'},
					$item->{'h_name'},
					$item->{'h_date'} );
			}	
		}
		else {
			my $temp_query_ver = sprintf ("%03d", $q_book_ver);

			foreach my $item (@$book_ver_info) {
				if ($item->{'book_ver'}=="$temp_query_ver") {
					download( $item->{'book_id'},
						$item->{'book_ver'},
						$item->{'book_date'},
						$item->{'abs_img_dir'},
						$item->{'h_name'},
						$item->{'h_date'} );
				}
			}
		}
	}

	case "listver" {
		my $pagecount=0;
		my $book_ver_info; 
		my $book_ver_info_page;
		my $item;
		my $mdid;
 
		my @match_book_index = @$match_book_list;

		if ( $#match_book_index==0 ) {	#only one match
			$item = shift @$match_book_list ;
			if ( $item->{'url'} =~ m{mdid=([0-9]*)} ) {
				$mdid=$1;
			}

			$book_ver_info_page = list_book_vers_page($mdid, $pagecount);

			while ( defined ($book_ver_info_page) ) {
				foreach my $item (@$book_ver_info_page) {
					push @$book_ver_info, $item;
				}

				$pagecount++;
				$book_ver_info_page = list_book_vers_page($mdid, $pagecount);
			}
		} else { 
			print "More than one kind of magazines.\n";
		}

		foreach my $item (@$book_ver_info) {
			print "name: " . $item->{'h_name'} . "\n";
			print "ver: " . $item->{'book_ver'} . "\n";
			print "date: " . $item->{'book_date'} . "\n";
			print "URL: http://tw.magv.com" . $item->{'ref_url'} . "\n";
			print "\n";
		}	
	}

	else {}

}

