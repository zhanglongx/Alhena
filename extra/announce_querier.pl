#! /usr/bin/perl -w

use strict;
use warnings;

use utf8;
binmode STDOUT, ":utf8";

use POSIX;
use Date::Calc;

use Getopt::Long;
use XML::LibXML;

use File::Find;
use File::Basename;

use HTTP::Cookies;
use LWP::UserAgent;

use alhena_database;

my $opt_help=0;
my $opt_stock;
my $opt_config;
my $opt_start;
my $opt_end;
my $opt_compounding = 0;

GetOptions( "help"         => \$opt_help,
            'name=s@{1,}'  => \$opt_stock,
            "file=s"       => \$opt_config,
            "start=s"      => \$opt_start,
            "end=s"        => \$opt_end,
           );

if( $opt_help )
{
    print "range [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -n, --name                    specifiy the subject\n";
    print "    -f, --file                    specifiy the config file [null]\n";
    print "    -s, --start                   start date\n";
    print "    -e, --end                     end date\n";
    exit(0);
}

( defined( $opt_config ) && -e $opt_config ) 
    or die "config file doesn't exist.\n";

defined( $opt_start ) or die "input start date\n";

unless( $opt_start =~ /[0-9]{4,4}-[0-9]{1,2}-[0-9]{1,2}/ )
{
    # FIXME: make it more strict
    die "start date format error\n";
}

unless( defined( $opt_end ) )
{
    $opt_end = strftime "%F", localtime $^T;
}

sub read_config;
sub get_url;
sub query_daily;

sub main;

main();

sub main
{
    my %config;
    
    read_config \%config;
    
    foreach my $stock (@{$config{codes}})
    {
        my %result;
        
        query_daily $stock, $config{keywords}, \%result;
        
        foreach my $date (sort keys %result)
        {
            printf "%s, %s\n", $date, $result{$date};
        }
    }
}

my @stock_all;

sub find_name
{
    my $file = fileparse( $File::Find::name );
    
    if( $file =~ m/^([0-9]+)\.csv/i )
    {
        my $stock = $1;
        
        push @stock_all, $stock;
    }
}

sub read_config
{
    my ($p_config) = @_;
    
    my $parser = XML::LibXML->new();
    my $c = $parser->parse_file( $opt_config );
    
    # codes
    my @id = map{$_->to_literal} @{$c->findnodes( '/config/codes/entry' )};
    
    if( scalar @id > 0 )
    {
        @{$p_config->{codes}} = @id;    
    }
    else
    {
        warn "config file ($opt_config) dosen't contains any code(s).\n";
    }
    
    if( defined( $opt_stock ) )
    {
        foreach my $t (@$opt_stock)
        {
            my $b_found = 0;
            
            foreach my $t2 (@{$p_config->{codes}})
            {
                if( $t == $t2 )
                {
                    $b_found = 1;
                    last;
                }
            }
            
            if( !$b_found )
            {
                push @{$p_config->{codes}}, $t;
            }
        }
    }
    
    unless( @{$p_config->{codes}} > 0 )
    {
        (-d "../database") or die "database path error\n";
        
        find( \&find_name, "../database" ); 
        
        @{$p_config->{codes}} = @stock_all;
    }
    
    # keywords
    @id = map{$_->to_literal} @{$c->findnodes( '/config/keywords/entry' )};
    
    if( scalar @id > 0 )
    {
        @{$p_config->{keywords}} = @id;
    }
    else {
        die "config file ($opt_config) doesn't contains any keyword(s).\n";
    }
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

sub query_daily
{
    my ($stock, $p_keywords, $p_result) = @_;
    my $page = 1;
    
    for ( my $page = 1; ; $page++ )
    {
        my $url_addr = "http://vip.stock.finance.sina.com.cn/corp/view/vCB_AllBulletin.php?stockid=$stock&Page=$page";
        my $content = get_url $url_addr;
        
        if( $content =~ m#<div class="datelist">(.*?)</div>#sg )
        {
            my $list = $1;
            my $b_end = 0;
            
            while( $list =~ m#(\d+-\d+-\d+).*?>(.*?)</a>#sg )
            {
                my $date = $1;
                my $announce = $2;
                
                Encode::from_to( $announce, "gb2312", "utf8" ); 
                Encode::_utf8_on( $announce );
                
                if( delta_days_wrapper( $date, $opt_end ) >= 0 )
                {
                    if( delta_days_wrapper( $opt_start, $date ) >= 0 )
                    {
                        foreach my $keyword (@$p_keywords)
                        {
                            if( index( $announce, $keyword ) >= 0 )
                            {
                                $p_result->{$date} = $announce;
                            }
                        }
                    }
                    else 
                    {
                        # source date is descending
                        $b_end = 1;
                        last;
                    }
                }
            }
            
            last  if( $b_end );
        }
        else 
        {
            last;
        }
    }
}
