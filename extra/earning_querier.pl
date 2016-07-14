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
my $opt_human=0;
my $opt_formula;
my $opt_season=0;
my $opt_title=0;
my $opt_database="../database";

GetOptions( "help"         => \$opt_help,
            "season=i"     => \$opt_season,
            "human"        => \$opt_human,
            "formula=s"    => \$opt_formula,
            "title"        => \$opt_title,
            "path=s"       => \$opt_database,
           );

if( $opt_help )
{
    print "$0 [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -s, --season                  season mode [0], (0..4)\n";
    print "    -f, --formula <string>        specifiy the formula\n";
    print "    -t, --title                   prefix with name\n";
    print "    -p, --path                    database path [$opt_database]\n";
    exit(0);
}

( $opt_season >= 0 && $opt_season < 5 )
    or die "season: $opt_season is not supported\n";

( defined( $opt_database ) && -d $opt_database )
    or die "database path: $opt_database doesn't exist\n";

sub read_stocks;
sub get_url;
sub read_in_csv;
sub print_out;
sub is_month;
sub format_number;

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
        
        print_out \%data_all, $stock; 
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
    
    do 
    {
        # Create a request
        $req = HTTP::Request->new(GET => $url_addr);
        $req->content_type('application/x-www-form-urlencoded');
        $req->content('query=libwww-perl&mode=dist');
       
        # Pass request to the user agent and get a response back
        $res = $ua->request($req);
    }while( $res->content =~ /ERR_TYPE_MYSQL/ );
   
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

        if( $line =~ /(^\S+)/g )
        {
            $entry = $1;
            
            $entry = '营业收入'  if( index( $entry, '营业收入' ) >= 0 );
            
            $entry = '净利润'    if( index( $entry, '净利润' ) >= 0 );
        }
        else
        {
            next;
        }

        while( $line =~ /\s+([-0-9.]+)/g )
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
            
            next  if( index( $element, "元" ) >= 0 );
            
            # hack for duplicated entry in cash flow table
            next  if( defined $p_dataall->{$entry}->{$month[$ele_count]} );

            if( scalar @month > 0 && defined $month[$ele_count] )
            {
                $p_dataall->{$entry}->{$month[$ele_count]} = $element;
                $ele_count++;
            }
        }
        
        $b_first_line = 0;
    }
}

sub print_out
{
    my ($p_dataall, $stock) = @_;
    my $formula = $opt_formula;

    if( defined( $formula ) )
    {
        # FIXME: more strict check
        while( $formula =~ m!([^ -+*/\(\)\d]+)!g )
        {
            my $entry = $1;
            
            Encode::_utf8_on($entry);
    
            defined( $p_dataall->{$entry} ) or
                die "$entry doesn't exist\n";
        }
        
        Encode::_utf8_on($formula);
        
        if( $opt_title )
        {
            print "$stock";
            print $opt_human ? " " : ", ";
        }

        print "$formula";
        print $opt_human ? " " : ", ";

        $formula =~ s/([^ -+*\/\(\)\d]+)/\$p_dataall->{$1}->{\$month}/g;
        
        foreach my $month (reverse sort keys %{$p_dataall->{应收账款}})
        {
            if( is_month $month )
            {
                my $val = $opt_human ? format_number eval( $formula ) : 
                                       eval $formula;
                if( defined( $val ) )
                {
                    print $val;
                    
                    print $opt_human ? " " : ", ";
                }
            }
        }
        
        print "\n";
    }
    else
    {
        print "$stock\n"  if( $opt_title );
        
        foreach my $entry (keys %$p_dataall)
        {
            printf "%s, ", $entry;
            
            foreach my $month (reverse sort keys %{$p_dataall->{$entry}})
            {
                if( is_month $month )
                {
                    my $val = $opt_human ? format_number $p_dataall->{$entry}->{$month} : $p_dataall->{$entry}->{$month};
 
                    if( defined( $val ) )
                    {
                        print $val;

                        print $opt_human ? " " : ", ";
                    }
                }
            }
            
            print "\n";
        }
    }
}

sub is_month
{
    my ($month) = @_;
    
    my @tbl_month = (3, 6, 9, 12);
    
    $month =~ s/\d{4,4}(\d{2,2})\d{2,2}/$1/;
    
    return 1  if ( $opt_season == 0 );
    
    return ( $month == $tbl_month[$opt_season - 1] );
}

sub format_number
{
    my ($number) = @_;

    return undef  if( !defined( $number ) );

    return $number  if( $number =~ /\./ );

    my $currnb = "";
    my ($mantis, $decimals) = split(/\./, $number, 2);
    $mantis =~ s/[^0-9]//g;
    while ( length($mantis) > 3 ) {
        $currnb = "'".(substr($mantis, length($mantis)-3, 3 )).$currnb;
        $mantis = substr($mantis, 0, length($mantis)-3);
    }
    $currnb = $mantis.$currnb;
    if ( $decimals ) { $currnb .= ".".$decimals; }
    else { $currnb .= ".00"; }
    return $currnb;
}
