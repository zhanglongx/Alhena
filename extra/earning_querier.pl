#! /usr/bin/perl -w

use strict;
use warnings;

use utf8;
binmode STDOUT, ":utf8";

use Encode;

use Getopt::Long;

use File::Find;
use File::Basename;

use HTTP::Cookies;
use LWP::UserAgent;

my $opt_help=0;
my $opt_formula;
my $opt_database="../database";

GetOptions( "help"         => \$opt_help,
            "formula=s"    => \$opt_formula,
            "path=s"       => \$opt_database,
           );

if( $opt_help )
{
    print "$0 [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -f, --formula <string>        specifiy the formula\n";
    print "    -p, --path                    database path [$opt_database]\n";
    exit(0);
}

( defined( $opt_database ) && -d $opt_database )
    or die "database path: $opt_database doesn't exist\n";
    
sub read_stocks;
sub get_url;
sub read_in_csv;
sub print_out;

sub main;

my @stock_all;

main();

sub main
{
    read_stocks;
    
    foreach my $stock (@stock_all)
    {
        my %data_all;
        
        read_in_csv \%data_all, "http://money.finance.sina.com.cn/corp/go.php/vDOWN_BalanceSheet/displaytype/4/stockid/$stock/ctrl/all.phtml";
        
        read_in_csv \%data_all, "http://money.finance.sina.com.cn/corp/go.php/vDOWN_ProfitStatement/displaytype/4/stockid/$stock/ctrl/all.phtml";
        
        read_in_csv \%data_all, "http://money.finance.sina.com.cn/corp/go.php/vDOWN_CashFlow/displaytype/4/stockid/$stock/ctrl/all.phtml";
        
        print_out \%data_all;
    }
}

sub find_name
{
    my $file = fileparse( $File::Find::name );
    
    if( $file =~ m/^([0-9]+)\.csv/i )
    {
        my $stock = $1;
        
        push @stock_all, $stock;
    }
}

sub read_stocks
{
    @stock_all = @ARGV;
    
    unless( scalar @stock_all > 0 )
    {
        # stored in @stock_all
        find( \&find_name, $opt_database ); 
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

sub read_in_csv
{
    my ($p_dataall, $url) = @_;
    
    my $content = get_url $url;
    my @month;
    my $b_first_line = 1;
    
    while( $content =~ /(.*)/mg )
    {
        my $line = $1;
        my $ele_count = 0;
        my $entry;
        
        Encode::from_to($line, "gb2312", "utf8");
        Encode::_utf8_on($line);

        while( $line =~ /\b(\S+)\b/g )
        {
            my $element = $1;
            
            if( $b_first_line )
            {
                if( $element =~ /\d{8,8}/ )
                {
                    push @month, $element;
                }
                
                next;
            }
            
            next  if( index( $element, "单位" ) >= 0 );
            
            next  if( index( $element, "元" ) >= 0 );
            
            if( !defined( $entry ) )
            {
                $entry = $element;
                next;   # skip start code
            }
            
            if( scalar @month > 0 && defined $month[$ele_count] )
            {
                $p_dataall->{$entry}->{$month[$ele_count]} = $element;
                $ele_count++;
            }
        }
        
        (scalar keys %{$p_dataall->{$entry}} == scalar @month) or
            warn "parse $entry failed\n";
        
        $b_first_line = 0;
    }
}

sub print_out
{
    my ($p_dataall) = @_;
    
    foreach my $entry (sort keys %$p_dataall)
    {
        printf "%s, ", $entry;
        
        foreach my $month (reverse sort keys %{$p_dataall->{$entry}})
        {
            printf "%d, ", $p_dataall->{$entry}->{$month};
        }
        
        print "\n";
    }
}
