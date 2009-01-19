#!/usr/bin/perl
use strict;
use utf8;
use pQuery;

use Data::Dumper;
use WWW::Mechanize;
use HTML::TableExtract;
use Carp;

my $site_url='http://tw.magv.com';
my $login_url='https://ssl.magv.com/pay/MemberLogin.aspx?r=%2fpay%2fMemberCenter.aspx';
my $memberinfo_url='https://ssl.magv.com/pay/MemberCenter.aspx';
my $book_list_url='http://tw.magv.com/MagazineList.aspx';
my $ver_list_url='http://tw.magv.com/ListMag.aspx';
my $cat_list_url='http://tw.magv.com/Category.aspx';

my $target_url;
my $target_file;
my $middle_dir="l08oo956l";

my $folder;

my $count;
my $countmax=300;

our $ua = WWW::Mechanize->new(
    env_proxy => 1,
    keep_alive => 1,
    timeout => 120,
    onerror => undef,
);

sub login {
	my ($username, $password) = @_;
	$ua->get($login_url);

#	$ua->submit_form( form_name=>'form1',
#			  fields => {	r=>'/pay/MemberCenter.aspx?',
#			  		__LASTFOCUS=>'',
#			  		__EVENTTARGET=>'',
#					__EVENTARGUMENT=>'',
#					__VIEWSTATE=>'/wEPDwUKMTMwNTE1MjExMQ9kFgICAxBkZBYCAgEPZBYGAgMPDxYEHgRUZXh0BQzliqDlhaXmnIPlk6EeC05hdmlnYXRlVXJsBSJodHRwOi8vdHcubWFndi5jb20vTWVtYmVyQWRkMC5hc3B4ZGQCBQ8PFgIfAQVaaHR0cHM6Ly9zc2wubWFndi5jb20vcGF5L01lbWJlckxvZ2luLmFzcHg/cj1odHRwJTNhJTJmJTJmdHcubWFndi5jb20lMmZFZGl0Q29sbGVjdGlvbi5hc3B4ZGQCBw8PFgQfAAUM5pyD5ZOh55m75YWlHwEFRmh0dHBzOi8vc3NsLm1hZ3YuY29tL3BheS9NZW1iZXJMb2dpbi5hc3B4P3I9JTJmcGF5JTJmTWVtYmVyQ2VudGVyLmFzcHhkZGQ=',
#					btnLogin=>'登入',
#			  		txtUserId=>"$username",
#					txtUserPass=>"$password", }
#			);

#	$ua->get("$memberinfo_url");

	$ua->get("https://ssl.magv.com/pay/MemberLogin.aspx?r=/pay/MemberCenter.aspx?__LASTFOCUS=&__EVENTTARGET=&__EVENTARGUMENT=&__VIEWSTATE=%2FwEPDwUKMTMwNTE1MjExMQ9kFgICAxBkZBYCAgEPZBYGAgMPDxYEHgRUZXh0BQzliqDlhaXmnIPlk6EeC05hdmlnYXRlVXJsBSJodHRwOi8vdHcubWFndi5jb20vTWVtYmVyQWRkMC5hc3B4ZGQCBQ8PFgIfAQVaaHR0cHM6Ly9zc2wubWFndi5jb20vcGF5L01lbWJlckxvZ2luLmFzcHg%2Fcj1odHRwJTNhJTJmJTJmdHcubWFndi5jb20lMmZFZGl0Q29sbGVjdGlvbi5hc3B4ZGQCBw8PFgQfAAUM5pyD5ZOh55m75YWlHwEFRmh0dHBzOi8vc3NsLm1hZ3YuY29tL3BheS9NZW1iZXJMb2dpbi5hc3B4P3I9JTJmcGF5JTJmTWVtYmVyQ2VudGVyLmFzcHhkZGQ%3D&txtUserId=$username&btnLogin=%E7%99%BB%E5%85%A5&txtUserPass=$password");
	
	my $content = $ua->content;

	# logout
#	$ua->get("$login_url?cmd=POS0000_5");


#	return {
#		credit => $credit,
#		creditsub => $creditsub,
#		date => $date,
#		account => $a,
#		balance => $balance,	
#	}; 


}

sub list_all_mags { # list all magazine

	my @tmp_book_list;
	my $book_list; 		# Global bookname=>url list 

	$ua->get($book_list_url);

	# parse html
	@tmp_book_list = $ua->find_all_links( url_regex => qr/ListMag/ );

	# map $book_list_url to something like $book_list ($bookname, $url);
	foreach my $book_item (@tmp_book_list) {
		$book_list->{$book_item->[1]} = $book_item->[0];
	}

	return $book_list;
}

sub search_book {

	my ($q_book_name) = @_;

	my @tmp_book_list;
	my $book_list; 		# Global bookname=>url list 
	my $match_book_list;
	my $count=0;
	
	if ($book_list == undef) { 
		$book_list = list_all_mags();
	}

	unless( utf8::is_utf8($q_book_name) ) {
		utf8::decode($q_book_name);
	}
	
	foreach my $item (keys %$book_list) {
		if ($item =~ m/$q_book_name/) {
			$match_book_list->[$count]->{'name'} = $item;
			$match_book_list->[$count++]->{'url'} = $book_list->{$item};
		}
	}

	return $match_book_list; 
}

sub list_book_vers_page {

	my ($mdid, $page_count) = @_;

	my $book_ver_info; 
	
	my $item_count=0;

	$ua->get("$site_url/ListMag.aspx?mdid=$mdid&page=$page_count");

	#do table extract
	my $te = new HTML::TableExtract->new( 'keep_html' =>1, 'keep_headers' => 1 );
	$te->parse($ua->content);
	
	# use HTML::TableExtract to filter useless information
	foreach my $ts ($te->tables) {
		if ( $ts->{'attribs'}->{'id'}='MagIssues1_DataList1') {
			foreach my $row ($ts->rows) {
				foreach my $single_div (@$row) {
					#do item extract
					my $pQ = pQuery ($single_div)
						->find("a")
							->each (
								sub { 
									$book_ver_info->[$item_count]->{'ref_url'} = $_->{'href'};
								} 
							) 
						->end() # find a 
						->find("img")
							->each (
								sub {
									$book_ver_info->[$item_count]->{'img'} = $_->{'src'};
									$_->{'src'} =~ s#/m/#/$middle_dir/#;	#replace real dir
									$_->{'src'} =~ s#[0-9]*.jpg##; 		#strip 001.jpg
									$book_ver_info->[$item_count]->{'abs_img_dir'} = $_->{'src'};
									if ($_->{'src'} =~ m#/(\w*)/([0-9]*)_([0-9]*)/# ) {
										$book_ver_info->[$item_count]->{'book_id'} = $1;
										$book_ver_info->[$item_count]->{'book_ver'} = $2;
										$book_ver_info->[$item_count]->{'book_date'} = $3;


									}
								}
							) 
						->end()
						->find("li")
							->eq(0)->each (
								sub {
									$book_ver_info->[$item_count]->{'h_name'} = pQuery($_)->text;
								} ) 
							->end()
							->eq(1)->each (
								sub { 
									$book_ver_info->[$item_count++]->{'h_date'} = pQuery($_)->text;
								} )
							->end()
						->end()
						;

				} # end of foreach $single_div
			} # end of foreach $row
		} # end of if $ts->{'attribs'}
	} # end of foreach

	return $book_ver_info;
}

sub preview_book {
	$ua->get("$site_url/privew.aspx?muid=37234");

	print $ua->content;
}

sub list_catgories {
	#useless
}

sub list_catgorie_books {
	#useless
	
	$ua->get("$cat_list_url?catID=403");

	print $ua->content;
}

sub write_book_info {


}

sub download {

	my ($book_id, $book_ver, $book_date, $abs_img_dir, $h_name, $h_date) = @_;
	my $archive;
	
	#mkdir
	unless (-e "$book_id") {
		mkdir ($book_id, 0755);
	}
	
	$folder = "$book_id". "/" . "$book_ver" . "_" . "$book_date" ; 

	unless (-e "$folder") {
		mkdir ($folder, 0755);
	}

	#batchdownload
	for ($count=1; $count<=$countmax; $count++) {
		$target_file = sprintf("%03d.jpg", $count);

		unless (-e "$folder/$target_file") {
			$target_url = sprintf("$abs_img_dir$target_file", $count);
			$ua->get("$target_url", ":content_file"=>"$folder/$target_file");
			last if ($ua->status == 404);
			sleep 5;
		}
	}

	#write_info
	system("echo $h_name > $folder/info.txt; echo $h_date >> $folder/info.txt");

	#zip
	$archive = "$folder" . ".zip";
	zip ("$archive", "$folder");
}

sub zip  {
	my ($target, $source) = @_;
	system ("zip $target $source/*\n");
}

