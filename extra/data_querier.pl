#! /usr/bin/perl -w
use strict;

use Getopt::Long;
use Date::Calc;
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

sub delta_days_wrapper
{
    my ($date1, $date2) = @_;
    my ($year1, $month1, $day1, $year2, $month2, $day2);
    
    if( $date1 =~ m/(\d+)-(\d+)-(\d+)/ )
    {
        $year1  = $1;
        $month1 = $2;
        $day1   = $3;
    }
    else
    {
        die "date1 format error\n";
    }
    
    if( $date2 =~ m/(\d+)-(\d+)-(\d+)/ )
    {
        $year2  = $1;
        $month2 = $2;
        $day2   = $3;
    }
    else
    {
        die "date1 format error\n";
    }
        
    return Date::Calc::Delta_Days( $year1, $month1, $day1, $year2, $month2, $day2 );
}

my $cookie_file="cookies_f.txt";

my @database;

sub query_data
{
    my ($stock, $year, $season, $end_date) = @_;
    
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
            
            last if( $one_day{'date'} eq $end_date );
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

my @xdr_info;

sub query_xdr{
    my ($stock, $last_date) = @_;
    
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
    $req = HTTP::Request->new(GET => "http://vip.stock.finance.sina.com.cn/corp/go.php/vISSUE_ShareBonus/stockid/$stock.phtml");
    $req->content_type('application/x-www-form-urlencoded');
    $req->content('query=libwww-perl&mode=dist');
   
    # Pass request to the user agent and get a response back
    $res = $ua->request($req);
   
    #return unless( $res->is_success );
   
    my $content = $res->content;
    
    while( $content =~ m#tr>(.*?)href="/corp/view/vISSUE#sg )
    {
        my $piece = $1;
        my %entry;

        if( $piece =~ m#<td>(\d+-\d+-\d+|--)</td>\s+?<td>(\d+-\d+-\d+|--)</td># )
        {
            $entry{'date'} = $2;
            
            next  if( $2 eq '--' );
            
            last  if( defined( $last_date ) && $last_date eq $2 ); # already had
            
            if( $piece =~ m#<td>\d+-\d+-\d+</td>\s+<td>([.0-9]+)</td>\s+<td>([.0-9]+)</td>\s+<td>([.0-9]+)</td># )
            {
                $entry{'gift'}     = $1;
                $entry{'donation'} = $2;
                $entry{'bouns'}    = $3;
                
                # print "$entry{'date'} $entry{'gift'} $entry{'donation'} $entry{'bouns'}\n";
                push @xdr_info, \%entry;
            }
        }
    }
}

sub do_xdr
{
    my ($value, $bouns, $gift, $donation) = @_;
    
    return ($value - $bouns / 10) / ( 1 + $gift / 10 + $donation / 10 );
}

sub xdr_one_day
{
    my ($entry) = @_;
    my %one_day = %$entry;

    foreach my $xdr (@xdr_info)
    {
        my %xdr_one = %$xdr;
        
        if( delta_days_wrapper( $one_day{'date'}, $xdr_one{'date'} ) >= 0 )
        {
            $one_day{'open'}  = do_xdr( $one_day{'open'},  $xdr_one{'bouns'}, $xdr_one{'gift'}, $xdr_one{'donation'} );
            $one_day{'high'}  = do_xdr( $one_day{'high'},  $xdr_one{'bouns'}, $xdr_one{'gift'}, $xdr_one{'donation'} );
            $one_day{'low'}   = do_xdr( $one_day{'low'},   $xdr_one{'bouns'}, $xdr_one{'gift'}, $xdr_one{'donation'} );
            $one_day{'close'} = do_xdr( $one_day{'close'}, $xdr_one{'bouns'}, $xdr_one{'gift'}, $xdr_one{'donation'} );
        }
    }
    
    return \%one_day;
}

my @old_database;
my @old_xdr_info;

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
        # xdr info
        if( /^#\s+(\d+-\d+-\d+)\s+([.0-9]+)\s+([.0-9]+)\s+([.0-9]+)/ )
        {
            my %one_xdr;
            
            $one_xdr{'date'}     = $1;
            $one_xdr{'gift'}     = $2;
            $one_xdr{'donation'} = $3;
            $one_xdr{'bouns'}    = $4;
            
            push @old_xdr_info, \%one_xdr;
        }
        
        # real data
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
    
    # start with xdr info
    foreach my $p_xdr_one (@xdr_info)
    {
        my %xdr_one = %$p_xdr_one;
        
        print WH "# $xdr_one{'date'} $xdr_one{'gift'} $xdr_one{'donation'} $xdr_one{'bouns'}\n";
    }
    
    foreach my $p_xdr_one (@old_xdr_info)
    {
        my %xdr_one = %$p_xdr_one;
        
        print WH "# $xdr_one{'date'} $xdr_one{'gift'} $xdr_one{'donation'} $xdr_one{'bouns'}\n";
    }
    
    # newest first
    foreach my $entry (@database)
    {
        my $p_one_day = xdr_one_day $entry;
        my %one_day   = %$p_one_day;
        
        print WH "$one_day{'date'} ";
        printf WH "%.2f %.2f %.2f %.2f %d\n",
                  $one_day{'open'}, $one_day{'high'}, $one_day{'low'}, $one_day{'close'}, $one_day{'vol'};
    }
    
    # then old
    foreach my $entry (@old_database)
    {
        my $p_one_day = xdr_one_day $entry;
        my %one_day   = %$p_one_day;
        
        print WH "$one_day{'date'} ";
        printf WH "%.2f %.2f %.2f %.2f %d\n",
                  $one_day{'open'}, $one_day{'high'}, $one_day{'low'}, $one_day{'close'}, $one_day{'vol'};
    }
    
    close WH;
}

my ($loc_sec, $loc_min, $loc_hour, $loc_day, $loc_mon, $loc_year) = localtime();

$loc_year += 1900;
$loc_mon  += 1;
my $loc_season = int( $loc_mon / 4 ) + 1;
# print "$loc_year-$loc_mon-$loc_day, season: $loc_season\n";

sub find_datafile {
    
    my $file = fileparse( $File::Find::name );
    
    pop @database       while( @database );
    pop @old_database   while( @old_database );
    pop @xdr_info       while( @xdr_info );
    pop @old_xdr_info   while( @old_xdr_info );
    
    if( $file =~ m/^([0-9]+)\.csv/i )
    {
        my $stock = $1;
        
        my ($end_year, $end_month, $end_day, $end_season) = read_old $file;
        
        # print "$end_year, $end_month, $end_day, $end_season\n";
        
        for ( my $year = $loc_year; $year >= $end_year; $year-- )
        {
            my $season_start = ($year == $loc_year) ? $loc_season : 4;
            
            for ( my $season = 4; $season >= 1; $season-- )
            {
                last   if( $year == $end_year && $season < $end_season );
                
                query_data $stock, $year, $season, "$end_year-$end_month-$end_day";
            }
        }
        
        if( scalar @old_xdr_info )
        {
            my $p_xdr_one = $old_xdr_info[0];
            my %xdr_one = %$p_xdr_one;
            
            query_xdr $stock, $xdr_one{'date'};
        }
        else
        {
            query_xdr $stock;
        }
        
        write_new $file;
    }
}

# almost everything in it
find( \&find_datafile, "$opt_path" ); 
