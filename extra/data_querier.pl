#! /usr/bin/perl -w
use strict;

use Getopt::Long;
use Date::Calc;
use File::Find;
use File::Basename;
use HTTP::Cookies;
use LWP::UserAgent;
use threads;

my $opt_help;
my $opt_threadnum = 3;
my $opt_equity = 1;
my $opt_path="../database";

GetOptions( "help"         => \$opt_help,  
            "equity"       => \$opt_equity,
            "threadnum=i"  => \$opt_threadnum,
            "path=s"       => \$opt_path,
           );

if( $opt_help )
{
    print "data_querier [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -e, --equity                  enable equity [$opt_equity]\n";
    print "    -t, --threadnum <num>         thread num (1,2,3) [$opt_threadnum]\n";
    print "    -p, --path <path>             database path\n";
    exit(0);
}

(-e $opt_path) or die "input path error\n";

($opt_threadnum > 0 && $opt_threadnum < 4) or die "threadnum error\n";

my @stock_array;

sub find_name
{
    my $file = fileparse( $File::Find::name );
    
    if( $file =~ m/^([0-9]+)\.csv/i )
    {
        my $stock = $1;
        
        push @stock_array, $stock;
    }
}

sub parse_date
{
    my ($date) = @_;
    
    if ( $date =~ m/(\d+)-(\d+)-(\d+)/ )
    {
        return ($1, $2, $3);
    }
    else
    {
        return (2007, 1, 1);
    }
}

sub delta_days_wrapper
{
    my ($date1, $date2) = @_;
    my ($year1, $month1, $day1) = parse_date $date1;
    my ($year2, $month2, $day2) = parse_date $date2;
    
    return Date::Calc::Delta_Days( $year1, $month1, $day1, $year2, $month2, $day2 );
}

sub do_xdr
{
    my ($value, $bouns, $gift, $donation) = @_;
    
    return ($value - $bouns / 10) / ( 1 + $gift / 10 + $donation / 10 );
}

sub get_season
{
    my ($month) = @_;
    
    return int( $month / 4 ) + 1;
}

sub process;
sub read_old;
sub write_new;
sub get_url;
sub query_xdr;
sub xdr_daily;
sub xdr_old_all;
sub query_daily;
sub get_daily;
sub query_equity;
sub get_equity;

sub main;

find( \&find_name, "$opt_path" ); 

main();

sub main
{
    my $stock_num = @stock_array;
    my $num_per_thread = int( $stock_num / $opt_threadnum ) + 1;
    my @thread_pool;
    
    # get local time for query_data() and query_xdr()
    my ($loc_sec, $loc_min, $loc_hour, $loc_day, $loc_mon, $loc_year) = localtime();
    
    $loc_year += 1900;
    $loc_mon  += 1;
    my $loc_season = get_season $loc_mon;
    # print "$loc_year-$loc_mon-$loc_day, season: $loc_season\n";
    
    for( my $thread_id=0; $thread_id < $opt_threadnum; $thread_id++ )
    {
        my @stocks;
        my %args;
        
        for( my $i = 0; $i < $num_per_thread; $i++ )
        {
            last if(0 == @stock_array);
            
            push (@stocks, shift @stock_array);
        }
        
        # creat thread for these stocks
        $args{'th_id'}    = $thread_id;
        $args{'p_stocks'} = \@stocks;
        $args{'loc_date'} = "$loc_year-$loc_mon-$loc_day";
        $args{'loc_seas'} = $loc_season;
        
        my $th = threads->create( 'process', \%args );
        
        push @thread_pool, $th;
    }
    
    foreach my $th ( @thread_pool )
    {
        $th->join();
    }
}

sub process
{
    my ($p_args) = @_;
    my $id       = $p_args->{'th_id'};
    my $p_stocks = $p_args->{'p_stocks'};
    my $loc_date = $p_args->{'loc_date'};
    my $loc_seas = $p_args->{'loc_seas'};
    
    foreach my $stock (@$p_stocks)
    {
        # XXX: @xdr_info @daily: [oldest] ... [newest]
        my (@xdr_info, @daily);
        
        next if ( read_old( $stock, \@xdr_info, \@daily ) );
        
        query_xdr ($stock, \@xdr_info, $loc_date);
        
        xdr_old_all( \@xdr_info, \@daily );
        
        get_daily ( $stock, \@xdr_info, \@daily, $loc_date );
        
        get_equity( $stock, \@daily );
        
        next if ( write_new( $stock, \@xdr_info, \@daily ) );
    }
}

sub read_old
{
    my ($stock, $p_xdr_info, $p_daily) = @_;
    my $filename = "$opt_path/$stock.csv";
    my $i_fails = 0;
    
    while( ! open FH, "$filename" )
    {
        if( $i_fails++ > 5 )
        {
            warn "can't open $filename for read: $!\n";
            return 1;
        }
    }
    
    while(<FH>)
    {
        # xdr info
        if( /^#\s+(\d+-\d+-\d+),([.0-9]+),([.0-9]+),([.0-9]+)/ )
        {
            my %one_xdr;

            $one_xdr{'date'}     = $1;
            $one_xdr{'gift'}     = $2;
            $one_xdr{'donation'} = $3;
            $one_xdr{'bouns'}    = $4;
            
            $one_xdr{'new'}      = 0;
                        
            push @$p_xdr_info, \%one_xdr;
        }
        
        # real data
        if( /(\d+-\d+-\d+),(.*),(.*),(.*),(.*),(.*),(.*)/ )
        {
            my %one_day;
            
            $one_day{'date'}   = $1;
            $one_day{'open'}   = $2;
            $one_day{'high'}   = $3;
            $one_day{'low'}    = $4;
            $one_day{'close'}  = $5;
            $one_day{'vol'}    = $6;
            $one_day{'equity'} = $7;
            
            push @$p_daily, \%one_day;
        }
    }
    
    close FH;
    
    return 0;
}

sub write_new
{
    my ($stock, $p_xdr_info, $p_daily) = @_;
    my $filename = "$opt_path/$stock.csv";
    my $i_fails = 0;
    
    while( ! open WH, ">$filename" )
    {
        if( $i_fails++ > 5 )
        {
            warn "can't open $filename for write: $!\n";
            return 1;
        }
    }
        
    # start with xdr info
    foreach my $p_xdr (@$p_xdr_info)
    {
        my $date     = $p_xdr->{'date'};
        my $gift     = $p_xdr->{'gift'};
        my $donation = $p_xdr->{'donation'};
        my $bouns    = $p_xdr->{'bouns'};
        
        print WH "# $date,$gift,$donation,$bouns\n";
    }
    
    # follow daily
    foreach my $p_entry (@$p_daily)
    {
        my $date     = $p_entry->{'date'};
        my $f_open   = $p_entry->{'open'};
        my $f_high   = $p_entry->{'high'};
        my $f_low    = $p_entry->{'low'};
        my $f_close  = $p_entry->{'close'};
        my $i_vol    = $p_entry->{'vol'};
        my $i_equity = $p_entry->{'equity'};
        
        print WH "$date,";
        printf WH "%.2f,%.2f,%.2f,%.2f,%d,%d\n",
                  $f_open, $f_high, $f_low, $f_close, $i_vol, $i_equity;
    }
    
    close WH;
    return 0;
}

sub get_url
{
    my ($url_addr) = @_;
    
    my $cookie_jar = HTTP::Cookies->new(
                        autosave => 1,
                        );
   
    my $ua = LWP::UserAgent->new;
    $ua->agent("MyApp/0.1 ");
    $ua->timeout(120);
   
    my $req;
    my $res;
    
    # Create a request
    $req = HTTP::Request->new(GET => $url_addr);
    $req->content_type('application/x-www-form-urlencoded');
    $req->content('query=libwww-perl&mode=dist');
   
    # Pass request to the user agent and get a response back
    $res = $ua->request($req);
   
    #return unless( $res->is_success );
   
    return $res->content;
}

sub query_xdr
{
    my ($stock, $p_xdr_info, $loc_date) = @_;
    my $url_addr = "http://vip.stock.finance.sina.com.cn/corp/go.php/vISSUE_ShareBonus/stockid/$stock.phtml";
    my $last_date;
    my @tmp_xdr;
    
    if( @$p_xdr_info )
    {
        my $p_last = $p_xdr_info->[@$p_xdr_info - 1];
        
        $last_date = $p_last->{'date'};
    }
    
    my $content = get_url $url_addr;
    
    while( $content =~ m#tr>(.*?)href="/corp/view/vISSUE#sg )
    {
        my $piece = $1;
        my %entry;

        if( $piece =~ m#<td>(\d+-\d+-\d+|--)</td>\s+?<td>(\d+-\d+-\d+|--)</td># )
        {
            $entry{'date'} = $2;
            
            # if n/a or not implemented
            next  if( $2 eq '--' || delta_days_wrapper( "$loc_date", $entry{'date'} ) > 0 );
            
            # already had
            last  if( defined( $last_date ) && $last_date eq $2 );
            
            if( $piece =~ m#<td>\d+-\d+-\d+</td>\s+<td>([.0-9]+)</td>\s+<td>([.0-9]+)</td>\s+<td>([.0-9]+)</td># )
            {
                $entry{'gift'}     = $1;
                $entry{'donation'} = $2;
                $entry{'bouns'}    = $3;
                
                $entry{'new'}      = 1;
                
                # FIXME: !!
                last  if( $entry{'bouns'} > 100 );
                
                # print "$entry{'date'} $entry{'gift'} $entry{'donation'} $entry{'bouns'}\n";
                push @tmp_xdr, \%entry;
            }
        }        
    }
    
    @tmp_xdr = reverse @tmp_xdr;
    
    push (@$p_xdr_info, shift @tmp_xdr)  while(@tmp_xdr);
}

sub xdr_daily
{
    my ($p_xdr_info, $p_entry, $b_check) = @_;
    my @tmp_xdr;
    
    foreach my $p_one_xdr (@$p_xdr_info)
    {
        push @tmp_xdr, $p_one_xdr;
    }
    
    # [newest] ... [oldest]
    @tmp_xdr = reverse @tmp_xdr;
    
    foreach my $p_one_xdr (@tmp_xdr)
    {
        my ($daily_date, $f_open, $f_high, $f_low, $f_close);
        my ($date, $bouns, $gift, $donation);
        
        last if ( $b_check && !$p_one_xdr->{'new'} ); # older can't be new
        
        $daily_date = $p_entry->{'date'};
        $f_open     = $p_entry->{'open'};
        $f_high     = $p_entry->{'high'};
        $f_low      = $p_entry->{'low'};
        $f_close    = $p_entry->{'close'};
        
        $date     = $p_one_xdr->{'date'};
        $bouns    = $p_one_xdr->{'bouns'};
        $gift     = $p_one_xdr->{'gift'};
        $donation = $p_one_xdr->{'donation'};
        
        last if ( delta_days_wrapper( $daily_date, $date ) < 0 );
        
        $p_entry->{'open'}  = do_xdr $f_open,  $bouns, $gift, $donation;  
        $p_entry->{'high'}  = do_xdr $f_high,  $bouns, $gift, $donation;
        $p_entry->{'low'}   = do_xdr $f_low,   $bouns, $gift, $donation;
        $p_entry->{'close'} = do_xdr $f_close, $bouns, $gift, $donation;     
    }
}

sub xdr_old_all
{
    my ($p_xdr_info, $p_daily) = @_;
    
    foreach my $p_entry (@$p_daily)
    {
        xdr_daily $p_xdr_info, $p_entry, 1;
    }
}

sub query_daily
{
    my ($stock, $p_daily, $year, $season, $end_date, $p_xdr_info) = @_;
    my $url_addr = "http://money.finance.sina.com.cn/corp/go.php/vMS_MarketHistory/stockid/$stock.phtml?year=$year&jidu=$season";
 
    my $content = get_url $url_addr;
    my $b_have_data = 0;
 
    while( $content =~ m#('_blank'.*?tr>)#sg )
    {
        my $pieces =  $1;
        my %one_day;
        
        if( $pieces =~ /date=(\d+-\d+-\d+)/ )
        {
            $one_day{'date'} = $1;
            
            last if( $one_day{'date'} eq $end_date );
        }
        else
        {
            warn "$stock date format error\n";
            next;
        }
        
        if( $pieces =~ />([0-9]+.[0-9]+)0<.*?>([0-9]+.[0-9]+)0<.*?>([0-9]+.[0-9]+)0<.*?>([0-9]+.[0-9]+)0<.*?>([0-9]+)</s )
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
        
        xdr_daily $p_xdr_info, \%one_day, 0;
        
        $one_day{'equity'} = 0; # in case no query_equity
        
        $b_have_data = 1;
        
        # [newst] ... [oldest]
        push @$p_daily, \%one_day;
    }

    return $b_have_data;    
}

sub get_daily
{
    my ($stock, $p_xdr_info, $p_daily, $loc_date) = @_;
    my ($loc_year, $loc_mon, $loc_day) = parse_date $loc_date;
    my ($end_year, $end_season, $end_date);
    
    if( @$p_daily )
    {
        my $p_last = $p_daily->[@$p_daily-1];
        
        $end_date = $p_last->{'date'};
        my ($year, $mon, $day) = parse_date $end_date;
        
        $end_year   = $year;
        $end_season = get_season $mon;
    }
    else
    {
        $end_year   = 2007;
        $end_season = 1;
        $end_date   = "2007-1-1";
    }
    
    my @tmp_daily; # [newest] ... [oldest]
    
    for ( my $year = $loc_year; $year >= $end_year; $year-- )
    {
        my $season_start = ($year == $loc_year) ? get_season( $loc_mon ) : 4;
        
        for ( my $season = $season_start; $season >= 1; $season-- )
        {
            last   if( $year == $end_year && $season < $end_season );
            
            last   if( !query_daily ( $stock, \@tmp_daily, $year, $season, $end_date, $p_xdr_info ) );
        }
    }
    
    @tmp_daily = reverse @tmp_daily;
    
    push @$p_daily, shift( @tmp_daily )   while(@tmp_daily);
}

sub query_equity
{
    my ($stock, $p_equity) = @_;
    my $url_addr = "http://vip.stock.finance.sina.com.cn/corp/go.php/vCI_StockStructureHistory/stockid/$stock/stocktype/LiuTongA.phtml";
    
    my $content = get_url $url_addr;
    
    while( $content =~ /value='([.0-9]+)' hoverText='(\d+-\d+-\d+)'/sg )
    {
        my %one;
        
        $one{'date'}   = $2;
        $one{'equity'} = $1 * 10000;
        
        push @$p_equity, \%one;
    }
    
    @$p_equity = reverse @$p_equity;
}

sub get_equity
{
    my ($stock, $p_daily) = @_;
    
    if( $opt_equity )
    {
        # [newest] ... [oldest]
        my @equity;
        
        query_equity $stock, \@equity;
        
        foreach my $p_entry (@$p_daily)
        {
            my $daily_date  = $p_entry->{'date'};
            
            next  if ( $p_entry->{'equity'} ); # already had
            
            foreach my $p_one_equity (@equity)
            {
                my $equity_date = $p_one_equity->{'date'};
                
                if( delta_days_wrapper( $equity_date, $daily_date ) >= 0 )
                {
                    $p_entry->{'equity'} = $p_one_equity->{'equity'};
                    last;
                }
            }
        }
    }
}
