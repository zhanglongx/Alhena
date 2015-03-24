#! /usr/bin/perl -w
use strict;

use Getopt::Long;
use File::Find;
use File::Basename;
use HTTP::Cookies;
use LWP::UserAgent;

my $opt_help;
my $opt_path="./test";

GetOptions( "help"        => \$opt_help,  
            "path=s"      => \$opt_path,
           );

if( $opt_help )
{
    print "data_querier [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -p, --path <path>             database path\n";
}

my $cookie_file="cookies_f.txt";

my @database;

sub query_data
{
    my ($stock, $year, $season, $end_year, $end_month, $end_day) = @_;
    
    my $cookie_jar = HTTP::Cookies->new(
                        file => $cookie_file,
                        autosave => 1,
                        );
   
    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");
    $ua->cookie_jar($cookie_jar);
    $ua->timeout(80);
   
    my $req;
    my $res;
    
    # Create a request
    $req = HTTP::Request->new(GET => "http://money.finance.sina.com.cn/corp/go.php/vMS_MarketHistory/stockid/$stock.phtml?year=$year&jidu=$season");
    $req->content_type('application/x-www-form-urlencoded');
    $req->content('query=libwww-perl&mode=dist');
   
    # Pass request to the user agent and get a response back
    $res = $ua->request($req);
   
    #return unless( $res->is_success );
   
    my $content = $res->content;
    my $is_have_data = 0;
 
    while( $content =~ m#('_blank'.*?tr>)#sg )
    {
        my $one_content =  $1;
        my %one_day;
        
        $is_have_data = 1;
        
        if( $one_content =~ /date=([0-9]+-[0-9]+-[0-9]+)/ )
        {
            $one_day{'date'} = $1;
            
            if( $one_day{'date'} =~ /([0-9]+)-([0-9]+)-([0-9]+)/ )
            {
                my $year  = $1;
                my $month = $2;
                my $day   = $3;
                
                last  if ( $year == $end_year && $month == $end_month && $day == $end_day );
            }
        }
        else
        {
            warn "$stock date format error\n";
            next;
        }
        
        if( $one_content =~ />([0-9]+.[0-9]+)0<.*?>([0-9]+.[0-9]+)0<.*?>([0-9]+.[0-9]+)0<.*?>([0-9]+.[0-9]+)0<.*?>([0-9]+)</s )
        {
            $one_day{'open'}  = $1;
            $one_day{'high'}  = $2;
            $one_day{'close'} = $3;
            $one_day{'low'}   = $4;
            $one_day{'vol'}   = $5;
        }
        else
        {
            warn "$stock data format error\n";
            next;
        }
        
        push @database, \%one_day;
    }
    
    return $is_have_data ? 0 : 1;
}

my @old_database;

sub read_old
{
    my ($filename) = @_;
    my $end_year   = 2000;
    my $end_month  = 1;
    my $end_day    = 1;
    my $end_season = 1;
    my $found_end  = 0;
    
    open FH, "$filename" or die "can't open $filename for read: $!";
    
    while(<FH>)
    {
        if( /([0-9]+-[0-9]+-[0-9]+)\s+([0-9]+\.[0-9]+)\s+([0-9]+\.[0-9]+)\s+([0-9]+\.[0-9]+)\s+([0-9]+\.[0-9]+)\s+([0-9]+)/ )
        {
            my $date = $1;
            my %one_day;
            
            $one_day{'date'}  = $date;
            $one_day{'open'}  = $2;
            $one_day{'high'}  = $3;
            $one_day{'low'}   = $4;
            $one_day{'close'} = $5;
            $one_day{'vol'}   = $6;
            
            if( $found_end == 0 && $date =~ /([0-9]+)-([0-9]+)-([0-9]+)/ )
            {
                $end_year  = $1;
                $end_month = $2;
                $end_day   = $3;
                
                $end_season = int( $end_month / 4 ) + 1;
                
                $found_end = 1;
            }
            
            push @old_database, \%one_day;
        }
    }
    
    close FH;
    
    return ($end_year, $end_month, $end_day, $end_season);
}

sub write_new
{
    my ($filename) = @_;
    
    open WH, ">$filename" or die "can't open $filename for write: $!";
    
    # newest first
    foreach my $entry (@database)
    {
        my %one_day = %$entry;
        
        print WH "$one_day{'date'} $one_day{'open'} $one_day{'high'} $one_day{'low'} $one_day{'close'} $one_day{'vol'}\n";
    }
    
    # then old
    foreach my $entry (@old_database)
    {
        my %one_day = %$entry;
        
        print WH "$one_day{'date'} $one_day{'open'} $one_day{'high'} $one_day{'low'} $one_day{'close'} $one_day{'vol'}\n";
    }
    
    close WH;
}

#for ( my $year=2014; $year > 2000; $year-- )
#{
#    my $is_no_data=0;
#    
#    for ( my $season = 4; $season > 0; $season-- )
#    {
#        print "$year, $season\n";
#        
#        $is_no_data = query_data( "300079", $year, $season );
#        
#        last if( $is_no_data );
#    }
#    
#    last if( $is_no_data );
#}

my ($loc_sec, $loc_min, $loc_hour, $loc_day, $loc_mon, $loc_year) = localtime();

$loc_year += 1900;
$loc_mon  += 1;
my $loc_season = int( $loc_mon / 4 ) + 1;
# print "$loc_year-$loc_mon-$loc_day, season: $loc_season\n";

sub find_datafile {
    
    my $file = fileparse( $File::Find::name );
    
    while( @database )
    {
        pop @database;
    }
    
    while( @old_database )
    {
        pop @old_database;
    }
    
    if( $file =~ m/^([0-9]+)\.csv/i )
    {
        my $stock = $1;
        
        my ($end_year, $end_month, $end_day, $end_season) = read_old $file;
        
        # print "$end_year, $end_month, $end_day, $end_season\n";
        
        for ( my $year = $loc_year; $year >= $end_year; $year-- ) # tempz!!
        {
            my $season_start = ($year == $loc_year) ? $loc_season : 4;
            
            for ( my $season = 4; $season >= 1; $season-- )
            {
                last   if( $year == $end_year && $season < $end_season );
                
                query_data $stock, $year, $season, $end_year, $end_month, $end_day;
            }
        }
        
        write_new $file;
    }
}

find( \&find_datafile, "$opt_path" ); 

#foreach my $entry (@database)
#{
#    my %one_day = %$entry;
#    
#    print "$one_day{'date'} $one_day{'open'} $one_day{'high'} $one_day{'close'} $one_day{'low'} $one_day{'vol'}\n";
#}

