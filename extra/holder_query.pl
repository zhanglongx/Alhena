#! /usr/bin/perl -w
use strict;

use Getopt::Long;
use Date::Calc;
use File::Find;
use File::Basename;
use HTTP::Cookies;
use LWP::UserAgent;
use Encode;
use threads;

my $opt_help;
my $opt_threadnum = 3;
my $opt_path="../database";

GetOptions( "help"         => \$opt_help,  
            "threadnum=i"  => \$opt_threadnum,
            "path=s"       => \$opt_path,
           );

if( $opt_help )
{
    print "data_querier [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -t, --threadnum <num>         thread num (1,2,3) [$opt_threadnum]\n";
    print "    -p, --path <path>             database path\n";
    exit(0);
}

(-e $opt_path) or die "input path error\n";
if( ! -e "$opt_path/holder" )
{
    mkdir "$opt_path/holder" or die "can't create holder dir:$!\n";
}

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

sub process;
sub write_new;
sub get_url;
sub query_holder;

sub main;

find( \&find_name, "$opt_path" ); 

main();

sub main
{
    my $stock_num = @stock_array;
    my $num_per_thread = int( $stock_num / $opt_threadnum ) + 1;
    my @thread_pool;
    
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
    
    foreach my $stock (@$p_stocks)
    {
        # [oldest] ... [newest]
        my @holder_info;
        
        query_holder( $stock, \@holder_info );
        
        next   if( write_new( $stock, \@holder_info ) );
    }
}

sub write_new
{
    my ($stock, $p_holder_info) = @_;
    my $filename = "$opt_path/holder/$stock.txt";
    my $i_fails = 0;
    
    while( ! open WH, ">$filename" )
    {
        if( $i_fails++ > 5 )
        {
            warn "can't open $filename for write: $!\n";
            return 1;
        }
    }

    foreach my $p_entry (@$p_holder_info)
    {
        my $date    = $p_entry->{'date'};
        my $name    = $p_entry->{'name'};
        my $vol     = $p_entry->{'vol'};
        my $percent = $p_entry->{'percent'};

        Encode::from_to( $name, "gb2312", "utf8" ); 

        print WH "$date,";
        print WH "$name";
        print WH ",$vol,$percent\n";
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

sub query_holder
{
    my ($stock, $p_holder_info) = @_;
    my $url_addr = "http://vip.stock.finance.sina.com.cn/corp/go.php/vCI_CirculateStockHolder/stockid/$stock/displaytype/100.phtml";
    
    my $content = get_url $url_addr;
 
    while( $content =~ /align="left" class="tdr">(.*?)<td height="5px" colspan="10"/sg )
    {
        my $pieces = $1;
        my $date;
        
        if( $pieces =~ /(\d+-\d+-\d+)/ )
        {
            $date = $1;
        }
        else
        {
            warn "date format error\n";
            next;
        }
        
        while( $pieces =~ m#<tr(.*?)</tr>#sg )
        {
            my %entry;
            my $table = $1;
            my $cnt = 0;
            
            next   if( $table =~ m#<strong># );
            
            $entry{'date'} = $date;
            
            while( $table =~ m#"center">(.*?)</div>#sg )
            {
                # FIXME:
                if( $cnt == 1 )
                {
                    $entry{'name'} = $1;
                }
                elsif ( $cnt == 2 )
                {
                    $entry{'vol'} = $1;
                }
                elsif ( $cnt == 3 )
                {
                    $entry{'percent'} = $1;
                }
                
                $cnt++;
            }
            
            push @$p_holder_info, \%entry;
        }
    }
    
    @$p_holder_info = reverse @$p_holder_info;
}
