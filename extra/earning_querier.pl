#! /usr/bin/perl -w

use strict;
use warnings;

use utf8;
binmode STDOUT, ":utf8";

use Term::ANSIColor;
use Encode;

use Getopt::Long;

use File::Find;
use File::Basename;
use File::Slurp qw( :edit read_file write_file );

use HTTP::Cookies;
use LWP::UserAgent;

use alhena_database;

my $MIN_CONTENT=3*1024;

my %tlb_trans = (
    '营业总收入'   => '营业总收入',
    '营业总成本'   => '营业总成本',
    '固定资产折旧' => '固定资产折旧',
    '净利润'       => '净利润',
    '稀释每股收益' => '每股收益',
    '市盈率'       => '股价*总股本/净利润',
    '市值'         => '股价*总股本',
    'PE'           => '股价/每股收益',
    'ROE'          => '净利润/(资产总计-负债合计)',
    '股本'         => '总股本',
    '提供劳务收到的现金' => '提供劳务收到的现金',
);

my $opt_help=0;
my $opt_debug=0;
my $opt_alias=0;
my $opt_color=33;
my $opt_human=0;
my $opt_reget=0;
my $opt_season=0;
my $opt_formula;
my $opt_title=0;
my $opt_database="../database";

GetOptions( "help"         => \$opt_help,
            "alias"        => \$opt_alias,
            "debug"        => \$opt_debug,
            "color=i"      => \$opt_color,
            "reget"        => \$opt_reget,
            "season=i"     => \$opt_season,
            "no-human"     => \$opt_human,
            "formula=s"    => \$opt_formula,
            "no-title"     => \$opt_title,
            "path=s"       => \$opt_database,
           );

if( $opt_help )
{
    print "$0 [options]\n";
    print "    -h, --help                    print this message\n";
    print "    -d, --debug                   print debug info\n";
    print "    -a, --alias                   print out alias list\n";
    print "    -c, --color                   print colorfully when > [$opt_color]\n";
    print "        --no-human                human readable\n";
    print "    -r, --reget                   force to reget newest data\n";
    print "    -s, --season                  season mode [$opt_season], (0..4)\n";
    print "    -f, --formula <string>        specifiy the formula or importting from file\n";
    print "        --no-title                prefix with name\n";
    print "    -p, --path                    database path [$opt_database]\n";
    exit(0);
}

if( $opt_alias )
{
    foreach (keys %tlb_trans)
    {
        print "$_: $tlb_trans{$_}\n";
    }

    exit(0);
}

$opt_color = $opt_color / 100;
$opt_human = !$opt_human;
$opt_title = !$opt_title;

( $opt_season >= 0 && $opt_season < 5 )
    or die "season: $opt_season error\n";

( defined( $opt_database ) && -d $opt_database )
    or die "database path: $opt_database doesn't exist\n";

sub read_config;
sub read_stocks;
sub load_data;
sub get_url;
sub read_in_csv;
sub substitute_alias;
sub print_out;
sub is_month;
sub format_number;
sub sub_val;
sub one_xdr;
sub reverse_xdr;
sub fill_pe;

sub main;

my @stock_all;

main();

sub main
{
    read_config;

    read_stocks;
    
    foreach my $stock (@stock_all)
    {
        my %data_all;
        my $content;

        warn "$stock\n"  if( $opt_debug );

        $content = load_data "http://money.finance.sina.com.cn/corp/go.php/vDOWN_BalanceSheet/displaytype/4/stockid/$stock/ctrl/all.phtml", $stock, "balance";
        read_in_csv \%data_all, $content;

        $content = load_data "http://money.finance.sina.com.cn/corp/go.php/vDOWN_ProfitStatement/displaytype/4/stockid/$stock/ctrl/all.phtml", $stock, "profit";
        read_in_csv \%data_all, $content;

        $content = load_data "http://money.finance.sina.com.cn/corp/go.php/vDOWN_CashFlow/displaytype/4/stockid/$stock/ctrl/all.phtml", $stock, "cashflow";
        read_in_csv \%data_all, $content;

        fill_pe \%data_all, $stock;

        print_out \%data_all, $stock; 
    }
}

sub read_config
{
    my @config;

    return  unless( defined( $opt_formula ) );

    if( -e $opt_formula )  # as file
    {
        open FH, $opt_formula;
        while( <FH> )
        {
            s/\n//g;
            push @config, $_;
        }
        close FH;
    }
    else # as arguments
    {
        push @config, $opt_formula;
    }

    $opt_formula = \@config;
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
    foreach (@ARGV)
    {
        push @stock_all, $_  if (-e "$opt_database/$_.csv");
    }
    
    unless( scalar @stock_all > 0 )
    {
        # stored in @stock_all
        find( \&find_name, $opt_database ); 
    }
}

sub substitute_alias
{
    my ($entry) = @_;

    # redefine entry
    foreach my $trans (keys %tlb_trans)
    {
        if( index( $entry, $trans ) >= 0 )
        {
            return $tlb_trans{$trans};
        }
    }

    return $entry;
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
    
    while(1) 
    {
        # Create a request
        $req = HTTP::Request->new(GET => $url_addr);
        $req->content_type('application/x-www-form-urlencoded');
        $req->content('query=libwww-perl&mode=dist');
       
        # Pass request to the user agent and get a response back
        $res = $ua->request($req);

        last  unless( $res->content =~ /ERR_TYPE_MYSQL/ || $res->content =~ m!<html! );

        last  unless( length( $res->content ) < $MIN_CONTENT );

        warn "maybe detected by sina\n";
        
        # XXX: wait for more, due to the sniffing
        sleep( 60 );
    };
   
    return $res->content;
}

sub load_data
{
    my($url, $stock, $sheet) = @_;

    my $filename = "$opt_database/earning/${stock}_$sheet.txt";
    my $content;

    # XXX: re-get only if forced or too old or illegal data
    if( $opt_reget || !(-e $filename) || (-M $filename > 6 * 30) || (-s $filename < $MIN_CONTENT) )
    {
        $content = get_url $url;

        open FH, ">$filename" or die "can't open $filename for writting: $!\n";
        print FH $content;
        close FH;

        # XXX: anti-sniffing
        sleep(10);
    }
    else
    {
        $content = read_file( "$filename" );
    }

    return $content;
}

sub read_in_csv
{
    my ($p_dataall, $content) = @_;
    
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
            $entry = substitute_alias $1;
        }
        else
        {
            next;
        }

        # null is for all
        my $b_in_formula = scalar( @$opt_formula ) ? 0 : 1;

        foreach my $__formula ( @$opt_formula )
        {
            my $formula = substitute_alias $__formula;

            if( index( $formula, $entry ) >= 0 ||
                index( $entry, '报表日期' ) >= 0 )
            {
                $b_in_formula = 1;

                last;
            }
        }

        next  unless( $b_first_line || $b_in_formula );

        while( $line =~ /\s+([-0-9.]+)/g )
        {
            my $element = $1;
            
            if( $b_first_line )
            {
                if( $element =~ /\d{8,8}/ )
                {
                    push @month, $element;
                }
            }
            
            next  if( index( $element, "元" ) >= 0 );
            
            # XXX: hack for duplicated entry in cash flow table
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

    if( defined( $opt_formula ) )
    {
        foreach my $__formula ( @$opt_formula )
        {
            # make local copy of formula
            my $formula = substitute_alias $__formula;

            # FIXME: more strict check
            while( $formula =~ m#[^- %+*/\(\)\d]+#g )
            {
                my $entry = $&;

                Encode::_utf8_on($entry);

                defined( $p_dataall->{$entry} ) or
                    die "$stock $entry doesn't exist\n";
            }

            Encode::_utf8_on($formula);

            if( $opt_title )
            {
                print "$stock";
                print $opt_human ? " " : ", ";
            }

            print "$formula";
            print $opt_human ? " " : ", ";

            $formula =~ s/[^- %+*\/\(\)\d]+/\$p_dataall->{$&}->{\$month}/g;

            foreach my $month (reverse sort keys %{$p_dataall->{报表日期}})
            {
                my $sub = $formula;
                $sub =~ s/(.*?)%/sub_val($p_dataall, $1, $month)/eg;

                if( is_month $month )
                {
                    my $val = $opt_human ? format_number eval( $sub ) : eval $sub;

                    if( defined( $val ) )
                    {
                        my $b_color = abs( $val ) > $opt_color  if( $formula =~ /%/ );

                        print $b_color ? colored( $val, 'yellow' ) : $val;

                        $month =~ /^\d{4,4}/;
                        print "($&)"  if( $opt_human );

                        print $opt_human ? " " : ", ";
                    }
                }
            }

            print "\n";
        }
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
    
    # FIXME: workaround for insufficience 
    #        of data, or will lead to undef
    #        warnings
    return 0  if ( $month < 20070000 );

    $month =~ s/\d{4,4}(\d{2,2})\d{2,2}/$1/;
    
    return 1  if ( $opt_season == 0 );
    
    return ( $month == $tbl_month[$opt_season - 1] );
}

sub format_number
{
    my ($number) = @_;

    return undef  if( !defined( $number ) );

    if( $number =~ /\./ )
    {
        # keep atmost 3 digts
        $number =~ s/(?<=\.\d\d\d)\d+//g;

        # no float point for large number
        return $number  unless( $number > 10000 );

        $number =~ s/\..*//g;
    }

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

sub sub_val
{
    my ($p_dataall, $sub, $m) = @_;
    my $last_val;
    
    foreach my $month (sort keys %{$p_dataall->{报表日期}})
    {
        next unless( is_month $month );

        if( $month == $m )
        {
            return 0  if( !defined( $last_val ) );

            return ( ( eval( $sub ) - $last_val ) / $last_val )  
                if $last_val;
        }

        $last_val = eval $sub;
    }

    return 0;
}

sub one_xdr
{
    my ($value, $bouns, $gift, $donation) = @_;

    # do xdr version   
    # return ($value - $bouns / 10) / ( 1 + $gift / 10 + $donation / 10 );
    return $value * ( 1 + $gift / 10 + $donation / 10 ) + $bouns / 10;
}

sub reverse_xdr
{
    my ($p_entry, $p_xdr_ratio) = @_;

    # XXX: is the reverse version of data_querier.pl
    foreach my $p_one_xdr (@$p_xdr_ratio)
    {
        my ($daily_date, $f_open, $f_high, $f_low, $f_close);
        my ($date, $bouns, $gift, $donation);
        
        $daily_date = $p_entry->{'date'};
        $f_open     = $p_entry->{'open'};
        $f_high     = $p_entry->{'high'};
        $f_low      = $p_entry->{'low'};
        $f_close    = $p_entry->{'close'};
        
        $date     = $p_one_xdr->{'date'};
        $bouns    = $p_one_xdr->{'bouns'};
        $gift     = $p_one_xdr->{'gift'};
        $donation = $p_one_xdr->{'donation'};
        
        next if ( delta_days_wrapper( $daily_date, $date ) < 0 );
        
        # not really necessary
        $p_entry->{'open'}  = one_xdr $f_open,  $bouns, $gift, $donation;  
        $p_entry->{'high'}  = one_xdr $f_high,  $bouns, $gift, $donation;
        $p_entry->{'low'}   = one_xdr $f_low,   $bouns, $gift, $donation;

        $p_entry->{'close'} = one_xdr $f_close, $bouns, $gift, $donation;     
    }
}

sub fill_pe
{
    my ($p_dataall, $stock) = @_;
    my (@xdr_info, @daily);
    my ($p_xdr_ratio, $p_daily) = (\@xdr_info, \@daily);

    read_old $stock, $opt_database, $p_xdr_ratio, $p_daily;

    foreach my $profit_date (sort keys %{$p_dataall->{报表日期}})
    {
        my $year;
        my $mon;
        my $day;

        next  unless( is_month( $profit_date ) );

        if( $profit_date =~ /(\d{4,4})(\d{2,2})(\d{2,2})/ )
        {
            ($year, $mon, $day) = ($1, $2, $3);
        }

        my $p_entry;

        # find last queryable close
        while( ($_=shift @$p_daily) )
        {
            my $data_date = $_->{'date'};
            
            unless( delta_days_wrapper( $data_date, "$year-$mon-$day" ) >= 0 )
            {
                unshift @$p_daily, $_;
                last;
            }

            $p_entry = $_;
        }
        
        unless( defined( $p_entry ) )
        {
            $p_dataall->{股价}->{$profit_date} = 0.0;
        }
        else
        {
            # unshift for next profit date
            unshift @$p_daily, $p_entry;

            reverse_xdr $p_entry, $p_xdr_ratio;

            $p_dataall->{股价}->{$profit_date} = $p_entry->{close};
        }

        # XXX: find first xdr bouns, here the bouns is binded to the last 
        #      profit date
        foreach my $p_one_xdr (@$p_xdr_ratio)
        {
            my $data_date  = $p_one_xdr->{'date'};
            my $data_bouns = $p_one_xdr->{'bouns'};
            
            if( delta_days_wrapper( "$year-$mon-$day", $data_date ) >= 0 )
            {
                # every 10 share
                $p_dataall->{股息率}->{$profit_date} = $data_bouns / 10;
                last;
            }
        }

        if( defined( $p_dataall->{股息率}->{$profit_date} ) && 
            $p_dataall->{股价}->{$profit_date} )
        {
            $p_dataall->{股息率}->{$profit_date} /= $p_dataall->{股价}->{$profit_date};
        }
        else
        {
            $p_dataall->{股息率}->{$profit_date} = 0.0
        }
    }
}
